* Encoding: UTF-8.
begin program.
import spss,spssaux

# Specify variables names to prefix.
# Variables between (inclusive) the specified variables in the .sav file will be modified.
variables = 'Total_Number_of_Fixations to average_pupil_size_of_both_eyes'

# Specify prefix. Use underscores instead of spaces
prefix ='wholeScreen_'

oldnames = spssaux.VariableDict().expand(variables)
newnames = [prefix + varname for varname in oldnames]
spss.Submit('rename variables (%s=%s).'%('\n'.join(oldnames),'\n'.join(newnames)))

end program.
