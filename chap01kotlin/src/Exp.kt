import java.lang.StringBuilder
import java.util.*

class Exp(type: ExpType) {

    var type = type
    var boolValue: Boolean = false
    var intValue: Int? = 0
    var charValue: Char? = null
    var stringValue: String = ""
    var cons: Cons? = null
    var function: Function? = null

    constructor(car: Exp, cdr: Exp): this(ExpType.CONS) {
        cons = Cons(car,cdr)
    }

    constructor(symbol: String): this(ExpType.SYMBOL) {
        stringValue = symbol
    }

    constructor(intValue: Int): this(ExpType.INTEGER) {
        this.intValue = intValue
    }

    constructor(boolValue: Boolean): this(ExpType.BOOLEAN) {
        this.boolValue = boolValue
    }

    constructor(cons: Cons): this(ExpType.CONS) {
        this.cons = cons
    }

    override fun toString(): String {
        return when (this.type) {
            ExpType.SYMBOL -> this.stringValue
            ExpType.BOOLEAN -> {if (this.boolValue) "#T" else "#F"}
            ExpType.CHARACTER -> this.charValue.toString()
            ExpType.INTEGER -> this.intValue.toString()
            ExpType.STRING -> String.format("\"%s\"", this.stringValue)
            ExpType.CONS -> listToString(this)
            ExpType.FUNCTION -> "<FUNCTION>"
        }
    }

    private fun listToString(exp: Exp): String {
        var sb = StringBuilder("(")
        var curr = exp
        var first = true
        while (curr.type == ExpType.CONS) {
            if (first) {
                first = false
            } else {
                sb.append(' ')
            }
            sb.append(curr.cons!!.car.toString())
            curr = curr.cons!!.cdr
        }
        if (curr.type != ExpType.SYMBOL || curr.stringValue != "NIL") {
            sb.append(" . ")
            sb.append(curr.toString())
        }
        sb.append(')')
        return sb.toString()
    }

    override fun equals(other: Any?): Boolean {
        var exp: Exp = other as Exp
        if (exp.type != this.type) {
            return false
        }
        return when (this.type) {
            ExpType.BOOLEAN -> boolValue == exp.boolValue
            ExpType.INTEGER -> intValue == exp.intValue
            ExpType.CHARACTER -> charValue == exp.charValue
            ExpType.SYMBOL -> stringValue == exp.stringValue
            ExpType.STRING -> stringValue == exp.stringValue
            ExpType.CONS -> cons!!.car.equals(exp.cons!!.car) && cons!!.cdr.equals(exp.cons!!.cdr)
            ExpType.FUNCTION -> false
        }
    }
}

class Cons(car: Exp, cdr: Exp) {

    var car = car
    var cdr = cdr

    private fun tailToString(consExp: Exp): String {
        var sb = StringBuilder()
        var first: Boolean = false
        var exp = consExp
        while (exp.type == ExpType.CONS) {
            if (first) {
                first = false
            } else {
                sb.append(", ")
            }
            var cons = exp.cons
            sb.append(cons!!.car.toString())
            exp = cons.cdr
        }
        if (exp.type != ExpType.SYMBOL || exp.stringValue != "NIL") {
            sb.append(" . ")
            sb.append(exp)
        }
        return sb.toString()
    }

    override fun toString(): String {
        var sb = StringBuilder(String.format("[LIST: %s", car))
        var tail = tailToString(cdr)
        sb.append(tail)
        sb.append("]")
        return sb.toString()
    }

}

class Function(params: Exp, body: Exp) {

    val params = params
    val body = body
    var isBuiltIn = false
    var sysName: String? = null

    constructor(sysName: String): this(Exp("NIL"), Exp("NIL")) {
        isBuiltIn = true
        this.sysName = sysName
    }

    /*
    fun getArgs(): LinkedList<String> {
        var args = LinkedList<String>()
        var p = params
        while (p.type == ExpType.CONS) {
            args.addLast(p.cons!!.car.stringValue)
            p = p.cons!!.cdr
        }
        return args
    }
    */

}

enum class ExpType {
    BOOLEAN, INTEGER, CHARACTER, SYMBOL, STRING, CONS, FUNCTION
}
