import java.time.Instant

object Main extends Foo with Bar:
  final val arg2: Long = 25L

  private def fn(arg1: Int, arg2: Int): Int =
    arg1 * Main.arg2.toInt + 5

  override def getFoo: String = "hello"

  @main
  def hello(arg1: Double, arg2: Int, arg3: String*): Unit =
    arg3.toList.sortWith((x, y) => x < y) match
      case Nil => println(s"arg1: $arg1")
      case xs  => println(s"$xs - ${Instant.now()}")

abstract class Foo:
  def getFoo: String

trait Bar
