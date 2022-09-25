<?php

function fn1($arg0, $arg1 = "") {
    print_r($arg0, $arg1);
    $add = fn($x) => $x + $arg0;
    $fn2 = function ($arg1) {
        $var = $arg0 . $arg1->arg0;
    };
}

class C{
    function memberFn($arg0){
        try {
            $arg0->run();
        } catch (\Throwable $th) {
            throw $th;
        }
    }
}
fn1(5, arg1: "");

?>

