$filePath = $ARGV[0]; 
$newSize = $ARGV[1];
open(my $fileH, "+<", $filePath) # open for update
or die "Can't open $filePath for update: $!";
truncate($fileH,$newSize);
close $fileH;
print "done\n";