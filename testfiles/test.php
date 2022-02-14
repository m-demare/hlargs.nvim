<?php

function fn1($arg0) {
    print_r($arg0, $arg1);
    $add = fn($x) => $x + $arg0;
    $fn2 = function ($arg1) {
        $var = $arg0 . $arg1->arg0;
    };
}

class C{
    function memberFn($arg0){
        $arg0->run();
    }
}

?>

