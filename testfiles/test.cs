class Program {
  public static void Main(string[] args) {
    Console.WriteLine("Hello");
    string str = "World";
    Console.Write(str);

    List<int> list = new();
    mystr a = new();
    a.argc = 0;
    a.SampleEvent += (a) => {
      a();
      Console.WriteLine("Event");
      list.Add(5);
    };

    GenericList<string> genList = new();
    genList.Add("Hello, world");
  }
}

class MyClass {
  public MyClass(int arg0, float arg1, params string[] args) {
    this.arg0_ = arg0;
    this.arg1 = arg1;
    this.args = args;
  }
  int arg0_;
  private float arg1;
  string[] args;

  int fn(char arg2, int arg3 = 0) {
    return arg3 + arg2;
  }
};

public struct mystr {
  public int argc;
  public delegate void Del();
  public event Del SampleEvent;
};

public class GenericList<T> {
  public void Add(T input) { }
}

