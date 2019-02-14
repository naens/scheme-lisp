import java.util.*

class Parser(tokenizer: Tokenizer) {

    val tokenizer = tokenizer

    var token: Token? = null        // used for unread

    private fun error(msg: String) {
        println("PARSER ERROR: $msg")
    }

    // list: [par_op] {exp} par_cl
    // list: [par_op] {exp} {dot} value par_cl
    private fun parseList(): Exp? {
        var resultExp = Exp(ExpType.CONS)
        var exps = LinkedList <Exp>()
        var exp: Exp?
        var dotExp: Exp?
        exp = parseExp()
        while (exp != null) {
            exps.addFirst(exp)
            exp = parseExp()
        }
        if (token == Token.PAR_CL) {
            dotExp = Exp("NIL")
        } else if (token == Token.DOT) {
            dotExp = parseExp()
            if (dotExp == null) {
                error("Bad dot expression.")
                return null
            }
            if (tokenizer.hasNext()) {
                token = tokenizer.next()
                if (token != Token.PAR_CL) {
                    error("Bad dot expression.")
                    return null
                }
            }
        } else {
            error("Bad list expression.")
            return null
        }

        if (exps.isEmpty()) {
            resultExp = Exp("NIL")
            return resultExp
        }

        var cons: Cons
        var car = exps.removeFirst()
        cons = Cons(car, dotExp)
        while (exps.isNotEmpty()) {
            car = exps.removeFirst()
            var cdr = Exp(ExpType.CONS)
            cdr.cons = cons
            cons = Cons(car, cdr)
        }
        resultExp.cons = cons
        return resultExp
    }

    private fun parseExp(): Exp? {
        if (!tokenizer.hasNext()) {
            return null
        }
        token = tokenizer.next()
        when (token) {
            Token.PAR_OP -> return parseList()
            Token.PAR_CL -> return null
            Token.QUOTE -> {
                var second: Exp? = parseExp()
                if (second == null) {
                    error("Bad quote expression.")
                    return null
                }
                var first = Exp("QUOTE")
                return Exp(first, Exp(second, Exp("NIL")))
            }
            Token.DOT -> return null
            Token.VALUE -> return token!!.value
        }
        error("Bad expression.")
        return null
    }

    fun parse(): Exp? {
        return parseExp()
    }
}
