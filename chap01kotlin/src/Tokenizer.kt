import java.lang.StringBuilder

class Tokenizer(input: String): Iterator<Token> {

    private val input = input

    private var nextToken: Token? = null

    private var index: Int = 0

    override fun next(): Token {
        if (nextToken != null) {
            //println("TOKEN:$nextToken")
            return nextToken as Token
        } else {
            throw NoSuchElementException()
        }
    }

    private fun readNumber(): Int {
        var sum: Int = 0
        while (index < input.length && input[index] >= '0' && input [index] <= '9') {
            sum = sum * 10 + input[index].toString().toInt()
            index++
        }
        return sum
    }

    private fun readSymbol(): String {
        var symbol = StringBuilder()
        while (index < input.length && input[index] != ' ' && input[index] != '(' && input[index] != ')'
            && input[index] != '\\' && input[index] != '\'' && input[index] != '"') {
            symbol.append(input[index])
            index++
        }
        return symbol.toString().toUpperCase()
    }

    private fun readString(): String {
        index++
        var sb = StringBuilder()
        while (index < input.length && input[index] != '"') {
            if (input[index] == '\\' && index != input.length - 1) {
                index++
            }
            sb.append(input[index])
            index++
        }
        if (index < input.length) {
            index++
        }
        return sb.toString()
    }

    override fun hasNext(): Boolean {
        while(index < input.length && input[index] == ' ') {
            index++
        }
        if (index == input.length) {
            return false
        }
        when (input[index]) {
            '(' -> {
                nextToken = Token.PAR_OP
                index++
            }
            ')' -> {
                nextToken = Token.PAR_CL
                index++
            }
            '\'' -> {
                nextToken = Token.QUOTE
                index++
            }
            '.' -> {
                nextToken = Token.DOT
                index++
            }
            '-' -> {
                if (index < input.length - 1 && input[index+1] >= '0' && input[index+1] <= '9') {
                    index++
                    var value = Exp(ExpType.INTEGER)
                    value.intValue = -readNumber()
                    nextToken = Token.VALUE
                    nextToken!!.value = value
                } else {
                    nextToken = Token.VALUE
                    nextToken!!.value = Exp("-")
                    index++
                }
            }
            in '0'..'9' -> {
                var value = Exp(ExpType.INTEGER)
                value.intValue = readNumber()
                nextToken = Token.VALUE
                nextToken!!.value = value
            }
            '"' -> {
                var value = Exp(ExpType.STRING)
                value.stringValue = readString()
                nextToken = Token.VALUE
                nextToken!!.value = value

            }
            '#' -> {
                if (input.length >= index + 3 && input[index+1] == '\\') {
                    var value = Exp(ExpType.CHARACTER)
                    value.charValue = input[index+2]
                    nextToken = Token.VALUE
                    nextToken!!.value = value
                    index += 3
                } else {
                    var value = Exp(ExpType.SYMBOL)
                    value.stringValue = readSymbol()
                    nextToken = Token.VALUE
                    nextToken!!.value = value
                }
            }
            else -> {
                var value = Exp(ExpType.SYMBOL)
                value.stringValue = readSymbol()
                nextToken = Token.VALUE
                nextToken!!.value = value
            }
        }
        return true
    }
}

enum class Token {
    PAR_OP, PAR_CL, QUOTE, DOT, VALUE;
    var value: Exp? = null
    override fun toString(): String {
        when (this) {
            VALUE ->  return String.format("VALUE (%s)", value.toString())
            else -> return super.toString()
        }
    }
}
