require "../../spec_helper"

describe "Code gen: tuple" do
  it "codegens tuple [0]" do
    run("{1, true}[0]").to_i.should eq(1)
  end

  it "codegens tuple [1]" do
    run("{1, true}[1]").to_b.should be_true
  end

  it "codegens tuple [1] (2)" do
    run("{true, 3}[1]").to_i.should eq(3)
  end

  it "codegens tuple [0]?" do
    run("{42, 'a'}[0]? || 84").to_i.should eq(42)
  end

  it "codegens tuple [1]?" do
    run("{'a', 42}[1]? || 84").to_i.should eq(42)
  end

  it "codegens tuple [2]?" do
    run("{'a', 42}[2]? || 84").to_i.should eq(84)
  end

  it "passed tuple to def" do
    run("
      def foo(t)
        t[1]
      end

      foo({1, 2, 3})
      ").to_i.should eq(2)
  end

  it "accesses a tuple type and creates instance from it" do
    run("
      struct Tuple
        def types
          T
        end
      end

      class Foo
        def initialize(@x : Int32)
        end

        def x
          @x
        end
      end

      t = {Foo.new(1)}
      f = t.types[0].new(2)
      f.x
      ").to_i.should eq(2)
  end

  it "allows malloc pointer of tuple" do
    run("
      struct Pointer
        def self.malloc(size : Int)
          malloc(size.to_u64)
        end
      end

      def foo(x : T)
        p = Pointer(T).malloc(1)
        p.value = x
        p
      end

      p = foo({1, 2})
      p.value[0] + p.value[1]
      ").to_i.should eq(3)
  end

  it "codegens tuple union (bug because union size was computed incorrectly)" do
    run(%(
      require "prelude"
      x = 1 == 1 ? {1, 1, 1} : {1}
      i = 2
      x[i]
      )).to_i.should eq(1)
  end

  it "codegens tuple class" do
    run(%(
      class Foo
        def initialize(@x : Int32)
        end

        def x
          @x
        end
      end

      class Bar
      end

      foo = Foo.new(1)
      bar = Bar.new

      tuple = {foo, bar}
      tuple_class = tuple.class
      foo_class = tuple_class[0]
      foo2 = foo_class.new(2)
      foo2.x
      )).to_i.should eq(2)
  end

  it "gets size at compile time" do
    run(%(
      struct Tuple
        def my_size
          {{ T.size }}
        end
      end

      {1, 1}.my_size
      )).to_i.should eq(2)
  end

  it "allows tuple covariance" do
    run(%(
       class Obj
         def initialize
           @tuple = {Foo.new}
         end

         def tuple=(@tuple)
         end

         def tuple
           @tuple
         end
       end

       class Foo
         def bar
           21
         end
       end

       class Bar < Foo
         def bar
           42
         end
       end

       obj = Obj.new
       obj.tuple = {Bar.new}
       obj.tuple[0].bar
       )).to_i.should eq(42)
  end

  it "merges two tuple types of same size (1)" do
    run(%(
       def foo
         if 1 == 2
           {"foo", 10}
         else
           {"foo", nil}
         end
       end

       val = foo[1]
       val || 20
       )).to_i.should eq(20)
  end

  it "merges two tuple types of same size (2)" do
    run(%(
       def foo
         if 1 == 1
           {"foo", 10}
         else
           {"foo", nil}
         end
       end

       val = foo[1]
       val || 20
       )).to_i.should eq(10)
  end

  it "assigns tuple to compatible tuple" do
    run(%(
      ptr = Pointer({Int32 | String, Bool | Char}).malloc(1_u64)

      # Here the compiler should cast each value
      ptr.value = {42, 'x'}

      val = ptr.value[0]
      val.as?(Int32) || 10
      )).to_i.should eq(42)
  end

  it "upcasts tuple inside compatible tuple" do
    run(%(
      def foo
        if 1 == 2
          {"hello", false}
        else
          {42, 'x'}
        end
      end

      val = foo[0]
      val.as?(Int32) || 10
      )).to_i.should eq(42)
  end

  it "assigns tuple union to compatible tuple" do
    run(%(
      tup1 = {"hello", false}
      tup2 = {3}
      tup3 = {42, 'x'}

      ptr = Pointer(typeof(tup1, tup2, tup3)).malloc(1_u64)
      ptr.value = tup3
      val = ptr.value[0]
      val.as?(Int32) || 10
      )).to_i.should eq(42)
  end

  it "upcasts tuple union to compatible tuple" do
    run(%(
      def foo
        if 1 == 2
          {"hello", false} || {3}
        else
          {42, 'x'}
        end
      end

      val = foo[0]
      val.as?(Int32) || 10
      )).to_i.should eq(42)
  end

  it "assigns tuple inside union to union with compatible tuple" do
    run(%(
      tup1 = {"hello", false}
      tup2 = {3}

      union1 = tup1 || tup2

      tup3 = {42, 'x'}
      tup4 = {4}

      union2 = tup3 || tup4

      ptr = Pointer(typeof(union1, union2)).malloc(1_u64)
      ptr.value = union2
      val = ptr.value[0]
      val.as?(Int32) || 10
      )).to_i.should eq(42)
  end

  it "upcasts tuple inside union to union with compatible tuple" do
    run(%(
      def foo
        if 1 == 2
          tup1 = {"hello", false}
          tup2 = {3}
          union1 = tup1 || tup2
          union1
        else
          tup3 = {42, 'x'}
          tup4 = {4}
          union2 = tup3 || tup4
          union2
        end
      end

      val = foo[0]
      val.as?(Int32) || 10
      )).to_i.should eq(42)
  end
end