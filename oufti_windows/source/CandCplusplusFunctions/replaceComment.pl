
use warnings;
$strings = $ARGV[0]; 


$strings=~ tr/#//d;

print $strings;
    
