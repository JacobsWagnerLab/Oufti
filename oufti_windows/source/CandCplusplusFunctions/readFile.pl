
use warnings;
$filePath = $ARGV[0]; 
#$frameNumber = $ARGV[1];

open(my $fileH, "<", $filePath) # open for update
or die "Can't open $filePath for update: $!";

#my $data = do {local $/; <$fileH> };
#print $data;

use File::ReadBackwards;
$fh = File::ReadBackwards->new($filePath) or 
die "can't read file: $!\n";

while ( defined($line = $fh->'#1000'))
{
    
}
#until ( $fh->eof ) {
 #           print $fh->readline ;
  #  }

#my $text = do {local($ARGV[1], $/); <$fh>};


close $fileH;