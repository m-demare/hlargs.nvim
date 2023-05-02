fun printSumIfBothNonNullAndIntStrIsValid(intOne: Int?, intStrTwo: String?) {
    intOne?.let { firstInt ->
        intStrTwo?.let { secondIntString ->
            try {
                println("Sum: ${firstInt + secondIntString.toInt()}")
            } catch(e: NumberFormatException) {
                println("Number format exception: $e")
            }
        }
    }
}

class Person(val pets: MutableList<Pet> = mutableListOf()) {
    fun addPet(pet: Pet) = pets.add(pet)
}

class Pet {
    constructor(owner: Person) {
        owner.pets.add(this)
    }
}
