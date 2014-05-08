use strict;

use IO::Socket;
use JSON;
use threads;

my $remote = IO::Socket::INET->new(
	Proto => 'udp',
	PeerAddr => 'localhost',
	PeerPort=> '8022',
	Reuse   => 1,
) or die "$!";
$remote->autoflush(1);      # pour que la sortie y aille tout de suite

my $heartbeat = threads->create(sub{
	while(1){
		print $remote 'heartbeat ';
		sleep(1);
	}
});

while(<$remote>){
	print $_;
}

$heartbeat->join();

close $remote;

# print $remote JSON->new->utf8->encode({'action','test'});

## while (<$remote>){
## 	print $_;
## }

## while (defined ($line = <STDIN>)) {
	## print $remote $line;
	## while (<$remote>){
		## print $_;
	## }
## }

# print "End of client\n";        # End of client
# close $remote;                  # Close socket

sub getLog(){
	my @buffer;
	my $lastLine;
	my $lastLineOffset;
	my $lastLineChecksum;
	my $LogFile = '/var/log/httpd/access_log';
	
	while(1){
		open( LOG, "$LogFile" ) || die("Couldn't open server log file \"$LogFile\" : $!");
		binmode LOG;
		
		if($lastLineOffset && $lastLineChecksum){
			print "Try a direct access to LastLineOffset=$lastLineOffset, LastLineChecksum=$lastLineChecksum\n";
			seek( LOG, $lastLineOffset, 0 );
			if (my $line = <LOG> ) {
				chomp $line;
				$line =~ s/\r$//;
				my $checksum = &CheckSum($line);
				if($checksum == $lastLineChecksum){
					print "Direct access after last parsed record (after line $lastLineOffset)\n";
					# $lastLineChecksum = $checksum;
					# $lastLineOffset   = tell LOG;
				}
				else {
					print "Direct access to last remembered record has fallen on another record.\nSo searching new records from beginning of log file...\n";
					# seek( LOG, 0, 0 );
					seek( LOG, -1000, 2 );
					print "lastLine : $lastLine\n";
					print "line : $line\n";
				}
			}
			else{
				print "Direct access to last remembered record is out of file.\nSo searching it from beginning of log file...\n";
				# seek( LOG, 0, 0 );
				seek( LOG, -1000, 2 );
			}
		}
		else {
			print "Searching new records from beginning of log file...\n";
			# seek( LOG, 0, 0 );
			seek( LOG, -1000, 2 );
		}
		
		# <stdin>;
		
		@buffer = ();
		my $lastLineOffsetNext;
		while (my $line = <LOG> ) {
			if(!$line){
				next;
			}
			
			$lastLine = $line;
			chomp $lastLine;
			$lastLine =~ s/\r$//;
			
			print "$lastLine\n";
			push(@buffer,$lastLine);
			
			$lastLineChecksum   = &CheckSum($lastLine);
			$lastLineOffset     = $lastLineOffsetNext;
			$lastLineOffsetNext = tell LOG;
		}
		
		# if(@buffer){
			# print $remote JSON->new->utf8->encode(@buffer);
		# }
		
		close(LOG);
		sleep(2);
	}
	
	#------------------------------------------------------------------------------
	# Function:     Return a checksum for an array of string
	# Parameters:	Array of string
	# Input:		None
	# Output:		None
	# Return: 		Checksum number
	#------------------------------------------------------------------------------
	sub CheckSum {
		my $string   = shift;
		my $checksum = 0;

		#	use MD5;
		# 	$checksum = MD5->hexhash($string);
		my $i = 0;
		my $j = 0;
		while ( $i < length($string) ) {
			my $c = substr( $string, $i, 1 );
			$checksum += ( ord($c) << ( 8 * $j ) );
			if ( $j++ > 3 ) { $j = 0; }
			$i++;
		}
		return $checksum;
	}
}
