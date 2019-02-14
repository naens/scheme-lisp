fun main(args: Array<String>) {
    var sxreader = SExpressionReader()

    var input: String?
    var eva = Evaluator()
    var env = makeGlobalEnvironment()
    sxreader.appendLine("(load \"chap01.scm\")")
    sxreader.appendLine("(chap01)")
    while (sxreader.hasNext()) {
        eva.evaluate(Parser(Tokenizer(sxreader.next())).parse()!!, env)
    }
    while (env.lookup("(EXIT)") == null) {
        print("> ")
        input = readLine()
        sxreader.appendLine(input)
        for (sexpr in sxreader) {
            var tokenizer = Tokenizer(sexpr)
            var parser = Parser(tokenizer)
            val exp = parser.parse()
            if (exp == null) {
                continue
            }
            var result = eva.evaluate(exp, env)
            if (result != null) {
                println(result)
            } else {
                var errorMessage = env.lookup("(ERROR)")
                if (errorMessage != null) {
                    println("ERROR: ${errorMessage.stringValue}")
                    env.undefGlobal("(ERROR)")
                } else {
                    println("?????????")
                }
            }
        }
    }
}
