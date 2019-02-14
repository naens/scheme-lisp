import java.util.*

class Environment {

    private var lists = LinkedList<LinkedList<Cell>>()

    fun defineLocal(name: String, value: Exp) {
        if (lists.size == 0) {
            lists.addFirst(LinkedList<Cell>())
        }
        var list: LinkedList<Cell> = lists.first
        var cell = Cell(name)
        cell.value = value
        list.addFirst(cell)
    }

    fun defineGlobal(name: String, value: Exp) {
        if (lists.size == 0) {
            lists.addFirst(LinkedList<Cell>())
        }
        var list: LinkedList<Cell> = lists.last
        var cell = Cell(name)
        cell.value = value
        list.addFirst(cell)
    }

    fun undefGlobal(name: String) {
        if (lists.size == 0) {
            return
        }
        var list: LinkedList<Cell> = lists.last
        for (cell in list) {
            if (cell.name.equals(name)) {
                list.remove(cell)
                return
            }
        }
    }

    private fun makeConsList(exps: List<Exp>): Exp {
        var list = exps.reversed()
        var curr = Exp("NIL")
        for (exp in list) {
            curr = Exp(Cons(exp, curr))
        }
        return curr
    }

    fun extend(names: Exp, values: LinkedList<Exp>): Environment {
        var newList = LinkedList<Cell>()
        var nameCons = names
        var i: Int = 0
        while (nameCons.type == ExpType.CONS) {
            var value = values[i]
            var name = nameCons.cons!!.car.stringValue
            var cell = Cell(name)
            cell.value = value
            newList.addLast(cell)
            nameCons = nameCons.cons!!.cdr
            i++
        }
        if (nameCons.type == ExpType.SYMBOL && nameCons.stringValue != "NIL"){
            var name = nameCons.stringValue
            var cell = Cell(name)
            cell.value = makeConsList(values.subList(i, values.size))
            newList.addLast(cell)
        } else {
            // TODO: error wrong number or type of parameters
        }
        // TODO: if parameters left then error
        var newLists = LinkedList<LinkedList<Cell>>()
        newLists.add(newList)
        for (list in lists) {
            newLists.addLast(list)
        }
        var newEnv = Environment()
        newEnv.lists = newLists
        return newEnv
    }

    private fun findCell(name: String): Cell? {
        for (list in lists) {
            for (cell in list) {
                if (cell.name == name) {
                    return cell
                }
            }
        }
        return null
    }

    fun lookup(name: String): Exp? {
        val cell = findCell(name)
        if (cell != null) {
            return cell.value
        }
        return null
    }

    fun update(name: String, value: Exp) {
        val cell = findCell(name)
        if (cell != null) {
            cell.value = value
        }
    }

}

class Cell(name: String) {
    var name = name
    var value: Exp? = null
}
