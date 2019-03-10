fun main(args: Array<String>) {
    val sxreader = SExpressionReader()

    var input: String?
    val eva = Evaluator()
    val env = makeGlobalEnvironment()
    //sxreader.appendLine("(load \"chap01.scm\")")
    //sxreader.appendLine("(chap01)")
    while (sxreader.hasNext()) {
        eva.evaluate(Parser(Tokenizer(sxreader.next())).parse()!!, env)
    }
    while (env.lookup("(EXIT)") == null) {
        print("> ")
        input = readLine()
        sxreader.appendLine(input)
        for (sexpr in sxreader) {
            val tokenizer = Tokenizer(sexpr)
            val parser = Parser(tokenizer)
            val exp = parser.parse()
            if (exp == null) {
                continue
            }
            val result = eva.evaluate(exp, env)
            if (result != null) {
                println(result)
            } else {
                val errorMessage = env.lookup("(ERROR)")
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
