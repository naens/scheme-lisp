import ExpType.*
import java.util.*

class Evaluator {

    fun evalArgs(argsConsExp: Exp, env: Environment): LinkedList<Exp> {
        var args = LinkedList<Exp>()
        var valConsExp = argsConsExp
        while (valConsExp.type != ExpType.SYMBOL && valConsExp.stringValue != "NIL") {
            args.addLast(evaluate(valConsExp.cons!!.car, env))
            valConsExp = valConsExp.cons!!.cdr
        }
        return args
    }

    data class LetBindings(val params: Exp, val args: LinkedList<Exp>)
    private fun getLetParamsArgs(letBindings: Exp, env: Environment): LetBindings{
        var binding = letBindings
        var argList = LinkedList<Exp>()
        var paramList = LinkedList<Exp>()
        while (binding.type == ExpType.CONS) {
            var bindingCons = binding.cons!!.car
            var param = bindingCons.cons!!.car
            paramList.addFirst(param)
            var argValue = evaluate(bindingCons.cons!!.cdr.cons!!.car, env)
            argList.addLast(argValue)
            binding = binding.cons!!.cdr
        }
        var current: Exp = Exp("NIL")
        for (param in paramList) {
            var newExp = Exp(ExpType.CONS)
            newExp.cons = Cons(param, current)
            current = newExp
        }
        return LetBindings(current, argList)
    }

    fun invoke(function: Exp, args: LinkedList<Exp>, env: Environment): Exp? {
        val f = function.function!!
        if (f.isBuiltIn) {
            return systemFunction(f.sysName!!, args, env)
        }

        var newEnv = env.extend(f.params, args)
        return eprogn(f.body, newEnv)
    }

    private fun eprogn(exps: Exp, env: Environment): Exp? {
        var exp = exps
        var result: Exp? = Exp("NIL")
        while (exp.type == ExpType.CONS) {
            result = evaluate(exp.cons!!.car, env)
            exp = exp.cons!!.cdr
        }
        return result
    }

    // (if <condition> <then> [<else>])
    private fun evalIfTail(exp: Exp, env: Environment): Exp? {
        var cdrCons = exp.cons
        if (cdrCons == null || cdrCons.cdr.cons == null) {
            env.defineGlobal("(ERROR)", Exp("if expression error"))
            return null
        }
        var cddrCons = cdrCons.cdr.cons!!
        var condition = cdrCons.car
        var conditionResult = evaluate(condition, env)
        if (conditionResult != null) {
            if (conditionResult.boolValue) {
                var consequence = cddrCons.car
                return evaluate(consequence, env)
            } else if (cddrCons.cdr.type == ExpType.CONS) {
                var alternative = cddrCons.cdr.cons!!.car
                return evaluate(alternative, env)
            }
        }
        env.defineGlobal("(ERROR)", Exp("if expression error"))
        return null
    }

    private fun evalAndTail(exp: Exp, env: Environment): Exp? {
        var result: Boolean = true
        var curr = exp
        while (result && curr.type == ExpType.CONS) {
            var value: Exp? = evaluate(curr.cons!!.car, env)
            if (value == null || value.type != ExpType.BOOLEAN) {
                return null
            }
            result = result && value.boolValue
            curr = curr.cons!!.cdr
        }
        return Exp(result)
    }

    private fun evalOrTail(exp: Exp, env: Environment): Exp? {
        var result: Boolean = false
        var curr = exp
        while (!result && curr.type == ExpType.CONS) {
            var value: Exp? = evaluate(curr.cons!!.car, env)
            if (value == null || value.type != ExpType.BOOLEAN) {
                return null
            }
            result = result || value.boolValue
            curr = curr.cons!!.cdr
        }
        return Exp(result)
    }

    // (cond {(<test> <expr>)} [(else <expr>)])
    private fun evalCondTail(exp: Exp, env: Environment): Exp? {
        var list = exp
        while (list.type == CONS) {
            var subList = list.cons!!.car
            var condExpr = subList.cons!!.car
            if (condExpr.type == ExpType.SYMBOL && condExpr.stringValue == "ELSE") {
                var altTail = list.cons!!.cdr
                if (altTail.type != ExpType.SYMBOL && altTail.stringValue != "NIL") {
                    env.defineGlobal("(ERROR)", Exp("cond expression \"else\" is not last"))
                    return null
                }
                var thenExpr = subList.cons!!.cdr.cons!!.car
                return evaluate(thenExpr, env)
            } else {
                var condVal = evaluate(condExpr, env)
                if (condVal == null) {
                    env.defineGlobal("(ERROR)", Exp("cond expression error"))
                    return null
                }
                if (condVal.type == ExpType.BOOLEAN && condVal.boolValue) {
                    var thenExpr = subList.cons!!.cdr.cons!!.car
                    return evaluate(thenExpr, env)
                }
            }
            list = list.cons!!.cdr
        }
        env.defineGlobal("(ERROR)", Exp("cond expression error"))
        return null
    }

    // (case <value> {(<value> <then-body>)} [(else <then-body>)])
    private fun evalCaseTail(exp: Exp, env: Environment): Exp? {
        if (exp.cons == null || exp.cons!!.cdr.type != ExpType.CONS) {
            env.defineGlobal("(ERROR)", Exp("case expression error"))
            return null
        }
        var valueExpression = exp.cons!!.car
        var value = evaluate(valueExpression, env)
        if (value == null) {
            env.defineGlobal("(ERROR)", Exp("case value error"))
            return null
        }
        var list = exp.cons!!.cdr
        while (list.type == CONS) {
            var subList = list.cons!!.car
            var condExpr = subList.cons!!.car
            if (condExpr.type == ExpType.SYMBOL && condExpr.stringValue == "ELSE") {
                var altTail = list.cons!!.cdr
                if (altTail.type != ExpType.SYMBOL && altTail.stringValue != "NIL") {
                    env.defineGlobal("(ERROR)", Exp("case expression \"else\" is not last"))
                    return null
                }
                //println("EVALCASE: $exp")
                return eprogn(subList.cons!!.cdr, env)
            } else {
                while (condExpr.type == CONS) {
                    var datum = condExpr.cons!!.car
                    if (value.equals(datum)) {
                        return eprogn(subList.cons!!.cdr, env)
                    }
                    condExpr = condExpr.cons!!.cdr
                }
            }
            list = list.cons!!.cdr
        }
        env.defineGlobal("(ERROR)", Exp("case expression error"))
        return null
    }

    private fun evalSetTail(exp: Exp, env: Environment): Exp? {
        var valExp = evaluate(exp.cons!!.cdr.cons!!.car, env)
        return if (valExp != null) {
            env.update(exp.cons!!.car.stringValue, valExp)
            Exp("NIL")
        } else {
            null
        }
    }

    private fun evalDefineTail(exp: Exp, env: Environment): Exp? {
        if (exp.cons!!.car.type == ExpType.SYMBOL) {
            var valExp = evaluate(exp.cons!!.cdr.cons!!.car, env)
            if (valExp != null) {
                env.defineLocal(exp.cons!!.car.stringValue, valExp)
                return Exp("NIL")
            } else {
                env.defineGlobal("(ERROR)", Exp("define expression error"))
                return null
            }
        } else {
            var cdrCons = exp.cons
            if (cdrCons == null) {
                env.defineGlobal("(ERROR)", Exp("define function error"))
                return null
            }
            val nameExp = cdrCons.car.cons!!.car
            val params = cdrCons.car.cons!!.cdr
            val body = cdrCons.cdr
            val function = Exp(ExpType.FUNCTION)
            function.function = Function(params, body)
            env.defineLocal(nameExp.stringValue, function)
            return Exp("NIL")
        }
    }

    // (lambda <params> <body>)
    private fun evalLambdaTail(exp: Exp, env: Environment): Exp? {
        var cdrCons = exp.cons
        if (cdrCons == null) {
            env.defineGlobal("(ERROR)", Exp("lambda expression error"))
            return null
        }
        val params = cdrCons.car
        val body = cdrCons.cdr
        var function = Function(params, body)
        var result = Exp(ExpType.FUNCTION)
        result.function = function
        return result
    }

    private fun evalLetTail(exp: Exp, env: Environment): Exp? {
        var cdrCons = exp.cons
        if (cdrCons == null) {
            env.defineGlobal("(ERROR)", Exp("let expression error"))
            return null
        }
        var body = cdrCons.cdr
        val (params, args) = getLetParamsArgs(cdrCons.car, env)
        val function = Exp(ExpType.FUNCTION)
        function.function = Function(params, body)
        return invoke(function, args, env)
    }

    fun evaluate(exp: Exp, env: Environment): Exp? {
        if (exp.type == ExpType.CONS) {
            var cons = exp.cons!!
            if (cons.car.type == ExpType.SYMBOL) {
                return when (cons.car.stringValue) {
                    "QUOTE" -> cons.cdr.cons!!.car
                    "IF" -> evalIfTail(cons.cdr, env)
                    "AND" -> evalAndTail(cons.cdr, env)
                    "OR" -> evalOrTail(cons.cdr, env)
                    "COND" -> evalCondTail(cons.cdr, env)
                    "CASE" -> evalCaseTail(cons.cdr, env)
                    "BEGIN" -> eprogn(cons.cdr, env)
                    "SET!" -> evalSetTail(cons.cdr, env)
                    "DEFINE" -> evalDefineTail(cons.cdr, env)
                    "LAMBDA" -> evalLambdaTail(cons.cdr, env)
                    "LET" -> evalLetTail(cons.cdr, env)
                    else -> {
                        var function = env.lookup(cons.car.stringValue)
                        if (function != null) {
                            var args = evalArgs(cons.cdr, env)
                            //println("EVALUATE: invoke ${cons.car.stringValue}, args=$args")
                            return invoke(function, args, env)
                        }
                        env.defineGlobal("(ERROR)", Exp("expression evaluation: unknown function ${cons.car.stringValue}"))
                        null
                    }
                }
            } else {
                var function = evaluate(cons.car, env)
                if (function != null) {
                    var args = evalArgs(cons.cdr, env)
                    return invoke(function, args, env)
                } else {
                    return null
                }
            }
        } else if (exp.type == ExpType.SYMBOL) {
            var value = env.lookup(exp.stringValue)
            if (value != null) {
                return value
            } else {
                return Exp("NIL")
            }
        } else {
            return exp
        }
    }
}
