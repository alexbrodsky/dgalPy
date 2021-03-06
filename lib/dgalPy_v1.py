import copy
import json
import pyomo.environ as pyo
from pyomo.environ import *
from pyomo.opt import SolverFactory
from pyomo.opt import SolverStatus, TerminationCondition

#import logging
#logging.basicConfig(filename= "dgalDebug.log", level=logging.DEBUG)
#--------------------------------------------------------------------------
def startDebug():
    f = open("debug.log","w")
    f.write("\nNEW RUN \n--------\n")

def debug(mssg,var):

    #nothing changed
    f = open("debug.log","a")
    f.write("\n\nDEBUG: ")
    f.write(str(mssg))
    f.write(":\n")
    f.write(str(var))
#---------------------------------------------------------------------------
'''
def debug(mssg,var):
    pass
'''
#--------------------------------------------------------------------------
'''
constraintSeq is a list of elements, each being either
bool, pyomo atomic constraint, or a list of pyomo atomic constraints
The function returns either bool (True or False) or a non-empty sequence of pyomo atomic constraints
'''
def All(constraintSeq):
    constraint = []
    print(constraintSeq)
    for c in constraintSeq:
        print(type(c))
        #if type(c) == bool:
        if type(c) == bool:
            if c == True:
                pass
            elif c == False:
                return False
        elif type(c) == list:  # i.e., it is pyomo symbolic list
            constraint.extend(c)
        else:  # i.e., it is a pyomo atomic constraint
            constraint.append(c)
    if constraint == []: return True
    else: return constraint

# tbd note: find out how to override Python all, any, and, or operators
#--------------------------------------------------------------------------
def dgalType(input):
    if type(input) == dict and "dgalType" in input.keys():
        if input["dgalType"] == "real?":
            return "real?"
        elif input["dgalType"] == "int?":
            return "int?"
    else:
        return "none"
#--------------------------------------------------------------------------
# initially invoked with counts = {"int?": -1, "real?": -1}
def enumDgalVars(input, counts):
    dgalVarFlag = dgalType(input)
    if dgalVarFlag == "real?":
            counts["real?"] += 1
            input["index"] = counts["real?"]
    elif dgalVarFlag == "int?":
            counts["int?"] += 1
            input["index"] = counts["int?"]
    elif type(input) == dict:
        for key in input:
            enumDgalVars(input[key],counts)
    elif type(input) == list or type(input) == set:
        for obj in input:
            enumDgalVars(obj,counts)
#-------------------------------------------------------------------------------------------------
#    -- assumes that pyomoModel has two var arrays: real[] and int[] with the numbers corresponding to counts;
#    -- assumes that counts capture the top index for "real?" and "int?" arrays
#    -- traverse input and replace dgalVarTypes with pyomo model variables
#    -- pyomo model should have sufficient length of real and int variable arrays to be assigned
#    -- to dgalType vars

def putPyomoVars(input, pyomoModel):
    dgalVar = dgalType(input)
    if dgalVar == "real?":
        return pyomoModel.real[input["index"]]
    if dgalVar == "int?":
        return pyomoModel.int[input["index"]]
    if type(input) == dict:    #i.e., dict that is not dgalTypes
        for key in input:
            input[key] = putPyomoVars(input[key], pyomoModel)
        return input
    if type(input) == list:
        for i in range(len(input)):
            input[i] = putPyomoVars(input[i], pyomoModel)
        return input
    return input    #can't contain dgalTypes

#-------------------------------------------------------------------------------
#- dgModel: an analytic performance model (AM) a python function
#- enumInput: is a dgalVar enumerated dgModel input
#- objective: is a function that gives value to optimize from output of dgModel
#- minMax: is either "min" or "max" to indicate whether the problem is minimization or
#          maximization of objective
#- constraints: is a function that returns dgalBoolean from output of dgModel;
#             this is going to serve as constraints of the optimization problem
#- config: is a structure with solver / algorithm configuration: for now it
#           is a dict {"solver": solver }, where solver is an available Pyomo solver
def createPyomoModel(dgModel, enumInputAndCounts, minMax, objective, constraints):
# extract enumInput & counts
    enumInput = enumInputAndCounts["enumInput"]
    counts = enumInputAndCounts["counts"]
# create Pyomo model and vars
    model = ConcreteModel()
    debug("model just created",model)
    model.realI = RangeSet(0,counts["real?"])
    model.intI = RangeSet(0,counts["int?"])
    model.real = Var(model.realI, domain=NonNegativeReals)
    model.int = Var(model.intI, domain=NonNegativeIntegers)
# insert pyomoVars
    inputWithPyomoVars = copy.deepcopy(enumInput)
    putPyomoVars(inputWithPyomoVars,model)
    debug("input w Pyomo vars",inputWithPyomoVars)
#    logging.debug("\n input w Pyomo vars: \n",inputWithPyomoVars)

# run dgModel (AM) on inputWithPyomoVars to get symbolic output
    output = dgModel(inputWithPyomoVars)
    constraintList = constraints(output)
    obj = objective(output)

# insert constaints and objective into Pyomo Model
    model.dgalConstraintList = constraintList
    model.dgalObjective = obj
    model.constrIndex = RangeSet(0,len(constraintList)-1)
    def pyomoConstraintRule(model, i):
        return model.dgalConstraintList[i]
    def pyomoObjectiveRule(model):
        return(model.dgalObjective)
    model.pyomoConstraint = Constraint(model.constrIndex, rule= pyomoConstraintRule)
    if minMax == "min":
        model.pyomoObjective = Objective(rule=pyomoObjectiveRule, sense=minimize)
    elif minMax == "max":
        model.pyomoObjective = Objective(rule=pyomoObjectiveRule, sense=maximize)
    else: print("\n dgal: minMax flag error\n")
    debug("pyomoModel before return", model)
    return model

#------------------------------------------------------------------------------
# pyomoResult is the result of optimizaiton from Pyomo Solver (in JSON)
# dgalType is either "real?" or "int?"
# index is a non-negative integer indicating position in pyomo var array
# the function returns the value of the corresponding variable
def varValue(pyomoResult,dgalType,index):
    # tbd; in the meantime just mock-up
    if dgalType == "real?":
        varString = 'real[' + str(index) + ']'
    else:
        varString = 'int[' + str(index) + ']'
    debug("varString", varString)
    pyomoResultVars = pyomoResult["Solution"][1]["Variable"]
    if varString in pyomoResultVars.keys():
        value = pyomoResultVars[varString]["Value"]
    else:
        value = 0.0
    return(value)
#---------------------------------------------------------------------
# assumes that pyomoResult has values for all enumerated dgalVars in enumInput
# answers is enumerated input initially, then replaced with corresponding values
# from pyomoResult

# I am here >> figure out return vs. update answer

def dgalOptResult(answer,pyomoResult):
    if pyomoResult["Solver"][0]["Termination condition"] == "infeasible":
        return "none"
    dgType = dgalType(answer)
    if dgType == "real?" or dgType == "int?":
        return varValue(pyomoResult, dgalType, answer["index"])
    if type(answer) == dict:    #i.e., dict that is not dgalTypes
        for key in answer:
            answer[key] = dgalOptResult(answer[key],pyomoResult)
        return answer
    if type(answer) == list:
        for i in range(len(answer)):
            answer[i] = dgalOptResult(answer[i],pyomoResult)
        return answer
    return answer  #can't contain dgalTypes

#-----------------------------------------------------------------
# model: pyomoModel w/objective and constraints
# config: is a dictionary with a solver setting, initially just
#          {"solver": solver}
# this function needs to be cleaned, by eliminating writing into files
def solvePyomoModel(model,enumInput,options):
    #if __name__ == '__main__':
        from pyomo.opt import SolverFactory
        import pyomo.environ
        opt = SolverFactory(options["solver"])
        results = opt.solve(model)
        debug("model after solve:",model)
#        model.pprint()
        model.solutions.store_to(results)
        results.write(filename='result.json', format='json')
        debug("model solutions:", model.solutions)
        debug("pyomo results:",results)
        f = open("result.json", "r")
        dictPyomoResult = json.loads(f.read())
        debug("dictPyomoResult read from results file", dictPyomoResult)

        dictPyomoResult["Problem"][0]["Lower bound"] = \
            str(dictPyomoResult["Problem"][0]["Lower bound"])
        dictPyomoResult["Problem"][0]["Upper bound"] = \
            str(dictPyomoResult["Problem"][0]["Upper bound"])
        debug("dictPyomoResult after stringifying bounds", dictPyomoResult )
        answer = copy.deepcopy(enumInput)
        debug("optAnswer deep copied from enumInput before dgalOptResult", answer)
        optAnswer = dgalOptResult(answer,dictPyomoResult)
        debug("optAnswer before dgalOptResult return",optAnswer)
        return {"dgalSolution": optAnswer, "report": dictPyomoResult }
        # return optAnswer
        # I am here: after adding "report", it says not serializable
#----------------------------------------------------------
#
def optimize(model,input,minMax,obj,constraints,options):
    # enumerate dgalVars in input
    counts = {"real?": -1, "int?": -1}
    enumInput = copy.deepcopy(input)
    enumDgalVars(enumInput, counts)
    debug("enumInput in py", enumInput)
    enumInputAndCounts = { "enumInput": enumInput, "counts":counts}
    pyomoModel = createPyomoModel(model,enumInputAndCounts,minMax,obj,constraints)
    debug("enumInput before solving",enumInput)
    answer = solvePyomoModel(pyomoModel,enumInput,options)
    return answer

# def min(model,input,obj,constraints,config):
def min(p):
    optAnswer = optimize( \
        p["model"],p["input"],"min",p["obj"],p["constraints"],p["options"])
    return optAnswer

# def max(model,input,obj,constraints,config):
def max(p):
    optAnswer = optimize( \
        p["model"],p["input"],"max",p["obj"],p["constraints"],p["options"])
    return optAnswer

#---------------------------------------------------------------------------
# model is an analytic model;
# input is a varParInput, i.e., input to the model annoted w/variable and parameters
# metrics is a function that gives a vector of metrics from the model output;
#         It is to be used for PairwisePenalty function, which computes (penatly)  distance
#         between 2 vectors of metrics
# trainingSeq is a list of pairs {inVector:..., metrics: ...}, where inVector is a vector
#         of values corresponding to variables in the model input sorted in the depth-first
#         traversal order; and metrics is a vector of metrics associated with the inVector.
#         The dimension of metrics must be the same as dimension of the metrics function output.
# pairwisePenalty is a function that, given 2 metric vectors, computes the penalty.
#         The computed penalty must be a distance function
# penalty is a function that, given a vector of penalties for each entry in the
#         trainingSeq, computes the overall penalty. Must be a metric function.
# options are options TBD
# NOTE: will need auxiliary functions that compute inVector from a model input,
#       and the other way around, that compute modelInput from varInput and inVector.
#
def train(model,input,metrics,trainingSeq, pairwisePenalty,penalty,options):
    return "tbd"
#
#-----------------------------------------------------------------------------
