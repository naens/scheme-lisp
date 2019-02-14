import java.lang.StringBuilder
import java.util.*

class SExpressionReader: Iterator<String> {
    /*
      The iterator can be in two states:
      (a) after returning a s-expression
        -> sexpr StringBuilder is empty
        -> level is 0
        -> index is outside of the s-expression
        -> lines LinkedList can be empty or not
      (b) after finishing reading the input, but the s-expression is not complete
        -> lines LinkedList is empty
        -> sexpr is not empty
        -> level is greater than 0
        -> index value does not point anywhere: no current line is being read
      If an invalid character is encountered (a closing parenthesis on level 0)
        -> lines is emptied
        -> sexpr remains empty
        -> index value has no meaning
      On hasNext:
        -> cannot be called twice in a row without next between
        (a) called after a s-expression has been returned
          -> find the next non-space character
          -> check that it's an open parenthesis
          -> set level to 1, advance index
          -> read the s-expression
             -> increase level on open parenthesis, decrease on closing
             -> advance index: increase index if on the same line
                               end of line:
                                 -> set index to 0
                                 -> delete current line
                                 -> no more lines => return false, state (b), level > 0
                               put each character read into sexpr
             -> if level becomes 0, then return true (keep index for future s-expressions)
        (b) continuing the s-expression after finishing all the lines before (new lines might be added)
          -> level is > 0
          -> set index to 0
          -> read the s-expression like in (a)
      On next:
        -> cannot be called if hasNext hasn't been called before and returned true
        -> convert sexpr to string and save
        -> empty the sexpr StringBuilder
        -> level must be 0
        -> index corresponds to the next reading location
            -> 0 if new line or no lines
            -> other value if a the next s-expression should be read from the current line
     */

    private var index: Int = 0

    private var level: Int = 0

    private var lines = LinkedList<String>()

    private var sexpr = StringBuilder()

    fun appendLine(line: String?) {
        if (line != null) {
            lines.addLast(line)
        }
    }

    // parses one s-expression from lines and returns it
    override fun next(): String {
        var result = sexpr.toString()
        sexpr = StringBuilder()
        return result
    }

    // skip the spaces until the end or a non-space character is found
    private fun findNextSExpr(): Boolean {
        while (lines.size > 0) {
            var line = lines[0]
            while (index < line.length && line[index] == ' ') {
                index++
            }
            if (index == line.length || line[index] == ';') {
                lines.removeFirst()
                index = 0
            } else if (index < line.length && line[index] != ' ') {
                return true
            }
        }
        return false
    }

    private fun readSymbol() {
        var line = lines[0]
        while (index < line.length && line[index] != ' ') {
            sexpr.append(line[index])
            index++
        }
    }

    override fun hasNext(): Boolean {
        var line: String
        if (level == 0) {
            if (!findNextSExpr()) {
                return false
            }
            line = lines[0]
            if (line[index] == '\'') {
                sexpr.append(line[index])
                index++
            }
            if (line[index] != '(') {
                if (line[index] != ')') {
                    readSymbol()
                    return true
                } else {
                    lines = LinkedList()
                    sexpr = StringBuilder()
                    level = 0
                    index = 0
                    return false
                }
            }
            sexpr.append(line[index])
            level = 1
            index++
        } else {
            if (lines.size == 0) {
                return false
            }
            line = lines[0]
        }

        var inString: Boolean = false
        var escape: Boolean = false
        var charHash: Boolean = false
        while (level > 0) {
            if (index == line.length || (!inString && !escape && line[index] == ';')) {
                lines.removeFirst()
                index = 0
                inString = false
                escape = false
                charHash = false
                sexpr.append(' ')
                if (lines.size == 0) {
                    return false
                }
                line = lines[0]
            }

            if (!escape && !inString) {
                when (line[index]) {
                    '(' -> level++
                    ')' -> level--
                }
            }
            if (escape) {
                escape = false
            } else if (!inString && line[index] == '#') {
                charHash = true
            } else {
                when (line[index]) {
                    '"' -> {
                        inString = !inString
                    }
                    '\\' -> {
                        if (inString || charHash) {
                            escape = true
                        }
                    }
                }
                charHash = false
            }

            sexpr.append(line[index])
            index++
        }
        if (index == line.length || (!inString && !escape && line[index] == ';')) {
            lines.removeFirst()
            index = 0
        }
        return true
    }

}
