import java.io.File
import java.lang.StringBuilder
import java.util.*

fun addSysFunction(name: String, env: Environment) {
    val exp = Exp(ExpType.FUNCTION)
    exp.function = Function(name)
    env.defineGlobal(name, exp)
}

fun makeGlobalEnvironment(): Environment {
    var environment = Environment()

    environment.defineGlobal("#T", Exp(true))
    environment.defineGlobal("#F", Exp(false))
    environment.defineGlobal("NIL", Exp("NIL"))

    addSysFunction("EXIT", environment)
    addSysFunction("BYE", environment)
    addSysFunction("END", environment)
    addSysFunction("READ", environment)
    addSysFunction("LOAD", environment)
    addSysFunction("DISPLAY", environment)
    addSysFunction("EVAL", environment)
    addSysFunction("APPLY", environment)
    addSysFunction("+", environment)
    addSysFunction("-", environment)
    addSysFunction("*", environment)
    addSysFunction("/", environment)
    addSysFunction("NOT", environment)
    addSysFunction("NUMBER?", environment)
    addSysFunction("PAIR?", environment)
    addSysFunction("CHAR?", environment)
    addSysFunction("STRING?", environment)
    addSysFunction("BOOLEAN?", environment)
    addSysFunction("SYMBOL?", environment)
    addSysFunction("FUNCTION?", environment)
    addSysFunction("PROCEDURE?", environment)
    addSysFunction("NULL?", environment)
    addSysFunction(">", environment)
    addSysFunction("<", environment)
    addSysFunction(">=", environment)
    addSysFunction("<=", environment)
    addSysFunction("=", environment)
    addSysFunction("EQUAL?", environment)
    addSysFunction("EQ?", environment)
    addSysFunction("LIST-REF", environment)
    addSysFunction("LIST", environment)
    addSysFunction("FIRST", environment)
    addSysFunction("REST", environment)
    addSysFunction("CONS", environment)
    addSysFunction("CAR", environment)
    addSysFunction("CDR", environment)
    addSysFunction("CAAR", environment)
    addSysFunction("CADR", environment)
    addSysFunction("CDAR", environment)
    addSysFunction("CDDR", environment)

    return environment
}

fun systemFunction(name: String, args: LinkedList<Exp>, env: Environment): Exp {
    return when (name) {
        "EXIT", "BYE", "END" -> sysExit(env)
        "READ" -> sysRead()
        "LOAD" -> sysLoad(args, env)
        "DISPLAY" -> sysDisplay(args)
        "EVAL" -> sysEval(args, env)
        "APPLY" -> sysApply(args, env)
        "+" -> sysPlus(args)
        "-" -> sysMinus(args)
        "*" -> sysMult(args)
        "/" -> sysDiv(args)
        "NOT" -> sysNot(args)
        "NUMBER?" -> sysIsNumber(args)
        "PAIR?" -> sysIsPair(args)
        "CHAR?" -> sysIsChar(args)
        "STRING?" -> sysIsString(args)
        "BOOLEAN?" -> sysIsBoolean(args)
        "SYMBOL?" -> sysIsSymbol(args)
        "FUNCTION?", "PROCEDURE?" -> sysIsFunction(args)
        "NULL?" -> sysNull(args)
        ">" -> sysGreater(args)
        "<" -> sysLess(args)
        ">=" -> sysGreaterEq(args)
        "<=" -> sysLessEq(args)
        "=", "EQUAL?", "EQ?" -> sysEq(args)
        "LIST-REF" -> sysListRef(args)
        "LIST" -> sysList(args)
        "FIRST" -> sysFirst(args)
        "REST" -> sysRest(args)
        "CONS" -> sysCons(args)
        "CAR", "CDR", "CADR", "CDAR", "CAAR", "CDDR" -> sysCXR(args, name.substring(1 until name.length-1))
        "SET-CDR!" -> sysSetCDR(args)
        else -> Exp("NIL")
    }
}

private fun sysExit(env: Environment): Exp {
    env.defineGlobal("(EXIT)", Exp(true))
    return Exp("NIL")
}

private fun sysRead(): Exp {
    var sxreader = SExpressionReader()
    while (!sxreader.hasNext()) {
        sxreader.appendLine(readLine())
    }
    var sexpr = sxreader.next()
    var tokenizer = Tokenizer(sexpr)
    var parser = Parser(tokenizer)
    var result = parser.parse()
    if (result != null) {
        return result
    }
    return Exp("NIL")
}

private fun sysLoad(args: LinkedList<Exp>, env: Environment): Exp {
    var fileName = args[0].stringValue
    var sxreader = SExpressionReader()
    var file: File = File(fileName)
    println("file is ${file.absolutePath}")
    val lines: List<String> = file.readLines()
    for (line in lines) {
        sxreader.appendLine(line)
    }
    var eva = Evaluator()
    var result: Exp? = null
    while (sxreader.hasNext()) {
        var sexpr = sxreader.next()
        var tokenizer = Tokenizer(sexpr)
        var parser = Parser(tokenizer)
        var exp = parser.parse()
        if (exp != null) {
            result = eva.evaluate(exp, env)
        } else {
            result = null
        }
    }
    if (result != null) {
        return result
    }
    return Exp("NIL")
}

private fun sysDisplay(args: LinkedList<Exp>): Exp {
    for (arg in args) {
        print("$arg ")
    }
    println()
    return Exp("NIL")
}

private fun sysEval(args: LinkedList<Exp>, env: Environment): Exp {
    var arg = args[0]
    var eva = Evaluator()
    var result = eva.evaluate(arg, env)
    if (result != null) {
        return result
    }
    return Exp("NIL")
}

private fun sysApply(args: LinkedList<Exp>, env: Environment): Exp {
    var function = args[0]
    var arguments = args[1]
    var eva = Evaluator()
    var ea = eva.evalArgs(arguments, env)
    var result = eva.invoke(function, ea, env)

    if (result != null) {
        return result
    }
    return Exp("NIL")

}

private fun sysPlus(args: LinkedList<Exp>): Exp {
    var sum: Int = 0
    for (arg in args) {
        if (arg.type == ExpType.INTEGER) {
            sum += arg.intValue!!
        }
    }
    return Exp(sum)
}

private fun sysMinus(args: LinkedList<Exp>): Exp {
    when (args.size) {
        0 -> return Exp(0)
        1 -> return Exp(-args[0].intValue!!)
        else -> {
            var res = args[0].intValue!!
            for (i in 1 until args.size) {
                var arg = args[i]
                if (arg.type == ExpType.INTEGER) {
                    res -= arg.intValue!!
                }
            }
            return Exp(res)
        }
    }
}

private fun sysMult(args: LinkedList<Exp>): Exp {
    var p: Int = 1
    for (arg in args) {
        if (arg.type == ExpType.INTEGER) {
            p *= arg.intValue!!
        }
    }
    return Exp(p)
}

private fun sysDiv(args: LinkedList<Exp>): Exp {
    return if (args.size != 2) {
        Exp("NIL")
    } else  {
        var res = args[0].intValue!!
        for (i in 1 until args.size) {
            var arg = args[i]
            if (arg.type == ExpType.INTEGER) {
                res /= arg.intValue!!
            }
        }
        Exp(res)
    }
}

private fun sysNot(args: LinkedList<Exp>): Exp {
    return Exp(!args[0].boolValue)
}

private fun sysIsNumber(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.INTEGER)
}

private fun sysIsPair(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.CONS)
}

private fun sysIsChar(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.CHARACTER)
}

private fun sysIsString(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.STRING)
}

private fun sysIsBoolean(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.BOOLEAN)
}

private fun sysIsSymbol(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.SYMBOL)
}

private fun sysIsFunction(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.FUNCTION)
}

private fun sysNull(args: LinkedList<Exp>): Exp {
    var arg = args[0]
    return Exp(arg.type == ExpType.SYMBOL && arg.stringValue == "NIL")
}

private fun sysGreater(args: LinkedList<Exp>): Exp {
    var n1 = args[0].intValue!!
    var n2 = args[1].intValue!!
    return Exp(n1 > n2)
}

private fun sysLess(args: LinkedList<Exp>): Exp {
    var n1 = args[0].intValue!!
    var n2 = args[1].intValue!!
    return Exp(n1 < n2)
}

private fun sysGreaterEq(args: LinkedList<Exp>): Exp {
    var n1 = args[0].intValue!!
    var n2 = args[1].intValue!!
    return Exp(n1 >= n2)
}

private fun sysLessEq(args: LinkedList<Exp>): Exp {
    var n1 = args[0].intValue!!
    var n2 = args[1].intValue!!
    return Exp(n1 <= n2)
}

private fun sysEq(args: LinkedList<Exp>): Exp {
    var n1 = args[0]
    var n2 = args[1]
    return Exp(n1.equals(n2))
}

private fun sysListRef(args: LinkedList<Exp>): Exp {
    var list = args[0]
    var pos = args[1].intValue!!
    while (list.type == ExpType.CONS && pos > 0) {
        list = list.cons!!.cdr
        pos--
    }
    if (pos == 0) {
        return list.cons!!.car
    } else {
        return Exp("NIL")
    }
}

private fun sysList(args: LinkedList<Exp>): Exp {
    var list = LinkedList<Exp>()
    for (item in args) {
        list.addFirst(item)
    }
    var cons: Exp = Exp("NIL")
    for (car in list) {
        cons = Exp(Cons(car, cons))
    }
    return cons
}

private fun sysFirst(args: LinkedList<Exp>): Exp {
    var list = args[0]
    if (list.type == ExpType.CONS) {
        return list.cons!!.car
    }
    return Exp("NIL")
}

private fun sysRest(args: LinkedList<Exp>): Exp {
    var list = args[0]
    if (list.type == ExpType.CONS) {
        return list.cons!!.cdr
    }
    return Exp("NIL")
}

private fun sysCons(args: LinkedList<Exp>): Exp {
    var car = args[0]
    var cdr = args[1]
    return Exp(Cons(car, cdr))
}

private fun sysSetCDR(args: LinkedList<Exp>): Exp {
    var cons = args[0].cons
    var value = args[1]
    cons!!.cdr = value
    return Exp("NIL")
}

private fun sysCXR(args: LinkedList<Exp>, path: String): Exp {
    var i = path.length - 1
    var element = args[0]
    while (i >= 0) {
        element = when (path[i]) {
            'A' -> if (element.type == ExpType.CONS) {
                element.cons!!.car
            } else {
                Exp("NIL")
            }
            'D' -> if (element.type == ExpType.CONS) {
                element.cons!!.cdr
            } else {
                Exp("NIL")
            }
            else -> Exp("NIL")
        }
        i--
    }
    return element
}
