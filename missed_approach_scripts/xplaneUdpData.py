# Class to get dataref values from XPlane Flight Simulator via network. 
# License: GPLv3

import datetime

from fileinput import filename
import os
import socket
import struct
import binascii
from time import sleep
import platform
import csv

class XPlaneIpNotFound(Exception):
  args="Could not find any running XPlane instance in network."

class XPlaneTimeout(Exception):
  args="XPlane timeout."

class XPlaneVersionNotSupported(Exception):
  args="XPlane version not supported."

class SenderNotHost(Exception):
  args="Packets received for another network device that isn't host."

class XPlaneUdp:

  '''
  Get data from XPlane via network.
  Use a class to implement RAI Pattern for the UDP socket. 
  '''
  
  #constants
  MCAST_GRP = "239.255.1.1"
  MCAST_PORT = 49707 # (MCAST_PORT was 49000 for XPlane10)
  
  def __init__(self):
    # Open a UDP Socket to receive on Port 49000
    self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    # list of requested datarefs with index number
    self.datarefidx = 0
    self.datarefs = {} # key = idx, value = dataref
    # values from xplane
    self.BeaconData = {}
    self.xplaneValues = {}
    self.defaultFreq = 3

  def __del__(self):
    for i in range(len(self.datarefs)):
      self.AddDataRef(next(iter(self.datarefs.values())), freq=0)
    self.socket.close()
  def WriteDataRef(self,dataref,value,vtype='float'):
    '''
    Write Dataref to XPlane
    DREF0+(4byte byte value)+dref_path+0+ spaces to complete the whole message to 509 bytes
    DREF0+(4byte byte value of 1)+ sim/cockpit/switches/anti_ice_surf_heat_left+0+spaces to complete to 509 bytes
    '''
    cmd = b"DREF\x00"
    dataref  =dataref+'\x00'
    string = dataref.ljust(500).encode()
    message = "".encode()
    if vtype == "float":
      message = struct.pack("<5sf500s", cmd,value,string)
    elif vtype == "int":
      message = struct.pack("<5si500s", cmd, value, string)
    elif vtype == "bool":
      message = struct.pack("<5sI500s", cmd, int(value), string)

    assert(len(message)==509)
    self.socket.sendto(message, (self.BeaconData["IP"], self.UDP_PORT))

  def AddDataRef(self, dataref, freq = None):

    '''
    Configure XPlane to send the dataref with a certain frequency.
    You can disable a dataref by setting freq to 0. 
    '''

    idx = -9999

    if freq == None:
      freq = self.defaultFreq

    if dataref in self.datarefs.values():
      idx = list(self.datarefs.keys())[list(self.datarefs.values()).index(dataref)]
      if freq == 0:
        if dataref in self.xplaneValues.keys():
          del self.xplaneValues[dataref]
        del self.datarefs[idx]
    else:
      idx = self.datarefidx
      self.datarefs[self.datarefidx] = dataref
      self.datarefidx += 1
    
    cmd = b"RREF\x00"
    string = dataref.encode()
    message = struct.pack("<5sii400s", cmd, freq, idx, string)
    assert(len(message)==413)
    self.socket.sendto(message, (self.BeaconData["IP"], self.BeaconData["Port"]))
    if (self.datarefidx%100 == 0):
      sleep(0.2)

  def GetValues(self):
    try:
      # Receive packet
      data, addr = self.socket.recvfrom(1472) # maximum bytes of an RREF answer X-Plane will send (Ethernet MTU - IP hdr - UDP hdr)
      # Decode Packet
      retvalues = {}
      # * Read the Header "RREFO".
      header=data[0:5]
      if(header!=b"RREF,"): # (was b"RREFO" for XPlane10)
        print("Unknown packet: ", binascii.hexlify(data))
      else:
        # * We get 8 bytes for every dataref sent:
        #   An integer for idx and the float value. 
        values =data[5:]
        lenvalue = 8
        numvalues = int(len(values)/lenvalue)
        for i in range(0,numvalues):
          singledata = data[(5+lenvalue*i):(5+lenvalue*(i+1))]
          (idx,value) = struct.unpack("<if", singledata)
          if idx in self.datarefs.keys():
            # convert -0.0 values to positive 0.0 
            if value < 0.0 and value > -0.001 :
              value = 0.0
            retvalues[self.datarefs[idx]] = value
      self.xplaneValues.update(retvalues)
    except:
      raise XPlaneTimeout
    return self.xplaneValues

  def FindIp(self):

      '''
      Find the IP of XPlane Host in Network.
      It takes the first one it can find. 
      '''
    
      self.BeaconData = {}
      hostIp = getHostIP()
      
      # open socket for multicast group. 
      sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
      sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      if platform.system() == "Windows":
        sock.bind(('', self.MCAST_PORT))
      else:
        sock.bind((self.MCAST_GRP, self.MCAST_PORT))
      mreq = struct.pack("=4sl", socket.inet_aton(self.MCAST_GRP), socket.INADDR_ANY)
      sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
      sock.settimeout(3.0)
      
      # receive data
      try:   
        
        for i in range(3):
          packet, sender = sock.recvfrom(1472)
          if sender[0] == hostIp:
            break
        else:
          raise SenderNotHost()
        print("XPlane Beacon: ", packet.hex())

        # decode data
        # * Header
        header = packet[0:5]
        if header != b"BECN\x00":
          print("Unknown packet from "+sender[0])
          print(str(len(packet)) + " bytes")
          print(packet)
          print(binascii.hexlify(packet))
          
        else:
          # * Data
          data = packet[5:21]
          # struct becn_struct
          # {
          # 	uchar beacon_major_version;		// 1 at the time of X-Plane 10.40
          # 	uchar beacon_minor_version;		// 1 at the time of X-Plane 10.40
          # 	xint application_host_id;			// 1 for X-Plane, 2 for PlaneMaker
          # 	xint version_number;			// 104014 for X-Plane 10.40b14
          # 	uint role;						// 1 for master, 2 for extern visual, 3 for IOS
          # 	ushort port;					// port number X-Plane is listening on
          # 	xchr	computer_name[strDIM];		// the hostname of the computer 
          # };
          beacon_major_version = 0
          beacon_minor_version = 0
          application_host_id = 0
          xplane_version_number = 0
          role = 0
          port = 0
          (
            beacon_major_version,  # 1 at the time of X-Plane 10.40
            beacon_minor_version,  # 1 at the time of X-Plane 10.40
            application_host_id,   # 1 for X-Plane, 2 for PlaneMaker
            xplane_version_number, # 104014 for X-Plane 10.40b14
            role,                  # 1 for master, 2 for extern visual, 3 for IOS
            port,                  # port number X-Plane is listening on
            ) = struct.unpack("<BBiiIH", data)
          hostname = packet[21:-1] # the hostname of the computer
          hostname = hostname[0:hostname.find(0)]
          if beacon_major_version == 1 \
              and beacon_minor_version <= 2 \
              and application_host_id == 1:
              self.BeaconData["IP"] = hostIp
              self.BeaconData["Port"] = port
              self.BeaconData["hostname"] = hostname.decode()
              self.BeaconData["XPlaneVersion"] = xplane_version_number
              self.BeaconData["role"] = role
              print("XPlane Beacon Version: {}.{}.{}".format(beacon_major_version, beacon_minor_version, application_host_id))
          else:
            print("XPlane Beacon Version not supported: {}.{}.{}".format(beacon_major_version, beacon_minor_version, application_host_id))
            raise XPlaneVersionNotSupported()

      except socket.timeout:
        print("XPlane IP not found.")
        raise XPlaneIpNotFound()
      finally:
        sock.close()

      return self.BeaconData

def getHostIP():
  hostName = socket.gethostname()
  hostIp = socket.gethostbyname(hostName)
  print("Host Name:", hostName, "\tHost IP:", hostIp)
  return hostIp

# Example how to use:
# You need a running xplane in your network. 
if __name__ == '__main__':

  current_time = datetime.datetime.now()
  formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S")
  file_name = current_time.strftime("%Y_%m_%d_%H_%M_%S") + ".csv"
  xp = XPlaneUdp()
  fixes = [["Start Flight",float("inf")],["Start Approach", 22.2], ["FAF", 6.3]]
  f_iter = iter(fixes)
  f_cur = next(f_iter)

  flight_time_ref = "sim/time/total_flight_time_sec"
  airspeed_ref = "sim/cockpit2/gauges/indicators/airspeed_kts_pilot"
  engine_speed_ref = "sim/cockpit2/engine/indicators/engine_speed_rpm[0]"
  alpha_ref = "sim/flightmodel2/position/alpha"
  roll_ref = "sim/cockpit2/gauges/indicators/roll_electric_deg_pilot"
  front_wheel_ref = "sim/flightmodel2/gear/on_ground[0]"
  pitch_ref = "sim/cockpit/gyros/the_vac_ind_deg"
  vvi_ref = "sim/cockpit2/gauges/indicators/vvi_fpm_pilot"
  alt_ref = "sim/cockpit2/gauges/indicators/altitude_ft_pilot" 
  heading_ref = "sim/cockpit2/gauges/indicators/heading_electric_deg_mag_pilot"
  dme_ref = "sim/cockpit/radios/nav1_dme_dist_m"
  hdef_ref = "sim/cockpit2/radios/indicators/nav1_hdef_dots_pilot"
  vdef_ref = "sim/cockpit2/radios/indicators/nav1_vdef_dots_pilot"
  turnrate_ref = "sim/cockpit2/gauges/indicators/turn_rate_roll_deg_pilot"
  flag_ref = "sim/cockpit2/radios/indicators/nav1_flag_from_to_pilot"
  pause_ref = "sim/time/paused"

  headers = [
    'sys_time', # Time format of curent system: YYYY-MM-DD HH:MM:S (PST)
    'sys_unix_time', # Unix milliseconds (Elapsed time since midnight of January 1st 1970 in UTC)
    'missn,_time', # Dataref: Total time since the flight got reset by something
    '_Vind,_kias', # Dataref: Indicated airspeed in knots, pilot
    'engn1,__rpm', # Dataref: Engine speed, revolutions per minute
    'alpha,__deg', # Dataref: The pitch relative to the flown path (angle of attack)
    '_roll,__deg', # Dataref: Indicated roll, in degrees, positive right. Source: electric gyro. Side: Pilot
    '_land,groll', # Dataref: Is this wheel on the ground
    'pitch,__deg', # Dataref: The indicated pitch on the panel for the first vacuum instrument
    '__VVI,__fpm', # Dataref: Indicated vertical speed in feet per minute, pilot system
    'p-alt,ftMSL', # Dataref: Indicated height, MSL, in feet, primary system, based on pilots barometric pressure input
    'hding,__mag', # Dataref: Indicated magnetic heading, in degrees. Source: electric gyro. Side: Pilot
    'pilN1,dme-d', # Dataref: Our distance in nautical miles from the beacon tuned in on nav1. override_navneedles
    'pilN1,h-def', # Dataref: CDI lateral deflection in dots, nav1, pilot
    'pilN1,v-def', # Dataref: CDI vertical deflection in dots, nav1, pilot
    'turnrate,__deg', # Dataref: Indicated rate-of-turn, in degrees deflection, for newer roll-augmented turn-indicators. Pilot side.
    'pi1N1,flag', # Nav-To-From indication, nav1, pilot, 0 is flag, 1 is to, 2 is from
    'is_paused' # Is the sim paused? (TRUE for paused, FALSE otherwise)
  ]



  try:
    beacon = xp.FindIp()
    print(beacon)

    xp.AddDataRef(flight_time_ref)
    xp.AddDataRef(airspeed_ref)
    xp.AddDataRef(engine_speed_ref)
    xp.AddDataRef(alpha_ref)
    xp.AddDataRef(roll_ref)
    xp.AddDataRef(front_wheel_ref)
    xp.AddDataRef(pitch_ref)
    xp.AddDataRef(vvi_ref)
    xp.AddDataRef(alt_ref)
    xp.AddDataRef(heading_ref)
    xp.AddDataRef(dme_ref)
    xp.AddDataRef(hdef_ref)
    xp.AddDataRef(vdef_ref)
    xp.AddDataRef(turnrate_ref)
    xp.AddDataRef(flag_ref)
    xp.AddDataRef(pause_ref)

    target_dir = r"C:\Users\D2Lab1\Documents\Boeing\Missed_Approach\Scripts\UDP Data"
    full_path = os.path.join(target_dir, file_name)

    with open(full_path, 'w', newline="") as csvfile:
      # creating a csv writer object
      csvwriter = csv.writer(csvfile)
      # writing the fields
      csvwriter.writerow(headers)
      file_location = os.path.realpath(csvfile.name)
      print("File location: ", file_location, '\n')
      
      while True:
        try:
          values = xp.GetValues()
          current_time = datetime.datetime.now()
          formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S")
          unix_time = current_time.timestamp() * 1000
          row = [
            formatted_time,
            unix_time,
            values[flight_time_ref],
            values[airspeed_ref],
            values[engine_speed_ref],
            values[alpha_ref],
            values[roll_ref],
            values[front_wheel_ref],
            values[pitch_ref],
            values[vvi_ref],
            values[alt_ref],
            values[heading_ref],
            values[dme_ref],
            values[hdef_ref],
            values[vdef_ref],
            values[turnrate_ref],
            values[flag_ref],
            values[pause_ref],
          ]
          
          csvwriter.writerow(row)
          csvfile.flush()
          print(current_time, 'data collected')
        except XPlaneTimeout:
          print("XPlane Timeout")
          print("File location: ", file_location, '\n')
          exit(0)

  except XPlaneVersionNotSupported:
    print("XPlane Version not supported.")
    exit(0)

  except XPlaneIpNotFound:
    print("XPlane IP not found. Probably there is no XPlane running in your local network.")
    exit(0)

  except SenderNotHost:
    print("Packets received from another network device that isn't host. Check X-Plane is running on local machine and rerun script.")
    exit(0)