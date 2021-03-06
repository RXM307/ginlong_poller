#!/usr/bin/perl -w

use warnings;
use AppConfig;  # used to read from a config file
#use WWW::Curl::Easy;
use HTTP::Request::Common qw(POST GET);
use LWP::UserAgent;			
use POSIX qw(strftime);
use Data::Dumper;

$| = 1;         # don't let Perl buffer I/O

# common
my $noTalks = 0;
my $reInits = 0;
my $lastPollTime = 0;
my $nextPollTime = 0;
my $lastPvoutputTime = 0;
my $nextPvoutputTime = 0;

use constant {
   LIVE_DATA_URL        => "http://pvoutput.org/service/r2/addstatus.jsp",
};

# create a new AppConfig object & auto-define all variables
my $config = AppConfig->new();

# define new variables
$config->define( "flags_debug!"          );
$config->define( "flags_pvoutput!"	 );
$config->define( "flags_pvoutputkey=s"	 );
$config->define( "flags_pvoutputid=s"	 );
$config->define( "secs_timeout=s"        );
$config->define( "secs_reinit=s"         );
$config->define( "time_start_poll=s"     );
$config->define( "time_end_poll=s"       );
$config->define( "paths_windows=s"       );
$config->define( "paths_other=s"         );
$config->define( "scripts_pvoutput=s"    );
$config->define( "scripts_create_rrd=s"  );
$config->define( "scripts_rrdtool_exe_win=s" );
$config->define( "scripts_rrdtool_exe_oth=s" );
$config->define( "serial_baud=s"         );
$config->define( "serial_port_win=s"     );
$config->define( "serial_port_oth=s"     );
$config->define( "serial_parity=s"       );
$config->define( "serial_databits=s"     );
$config->define( "serial_stopbits=s"     );
$config->define( "serial_handshake=s"    );
$config->define( "serial_datatype=s"     );
$config->define( "hex_data_to_follow_index=s" );
$config->define( "hex_capacity_index=s"  );
$config->define( "hex_capacity_length=s" );
$config->define( "hex_firmware_index=s"  );
$config->define( "hex_firmware_length=s" );
$config->define( "hex_model_index=s"     );
$config->define( "hex_model_length=s"    );
$config->define( "hex_manuf_index=s"     );
$config->define( "hex_manuf_length=s"    );
$config->define( "hex_serial_index=s"    );
$config->define( "hex_serial_length=s"   );
$config->define( "hex_other_index=s"     );
$config->define( "hex_other_length=s"    );
$config->define( "hex_confserial_index=s" );
$config->define( "sendhex_initialise=s"   );
$config->define( "sendhex_serial=s"       );
$config->define( "sendhex_conf_serial1=s" );
$config->define( "sendhex_conf_serial2=s" );
$config->define( "sendhex_data=s"        );
$config->define( "recvhex_serial=s"      );
$config->define( "recvhex_conf_serial=s" );
$config->define( "recvhex_data=s"        );
$config->define( "data_vpv1_hexcode=s"  );
$config->define( "data_vpv1_multiply=s"  );
$config->define( "data_vpv1_measure=s"  );
$config->define( "data_vpv1_index=s"  );
$config->define( "data_vpv1_descr=s"  );
$config->define( "data_vpv1_flip=s"  );
$config->define( "data_vpv2_hexcode=s"  );
$config->define( "data_vpv2_multiply=s"  );
$config->define( "data_vpv2_measure=s"  );
$config->define( "data_vpv2_index=s"  );
$config->define( "data_vpv2_descr=s"  );
$config->define( "data_vpv2_flip=s"  );
$config->define( "data_ipv1_hexcode=s"  );
$config->define( "data_ipv1_multiply=s"  );
$config->define( "data_ipv1_measure=s"  );
$config->define( "data_ipv1_index=s"  );
$config->define( "data_ipv1_descr=s"  );
$config->define( "data_ipv1_flip=s"  );
$config->define( "data_ipv2_hexcode=s"  );
$config->define( "data_ipv2_multiply=s"  );
$config->define( "data_ipv2_measure=s"  );
$config->define( "data_ipv2_index=s"  );
$config->define( "data_ipv2_descr=s"  );
$config->define( "data_ipv2_flip=s"  );
$config->define( "data_emonth_hexcode=s"  );
$config->define( "data_emonth_multiply=s"  );
$config->define( "data_emonth_measure=s"  );
$config->define( "data_emonth_index=s"  );
$config->define( "data_emonth_descr=s"  );
$config->define( "data_emonth_flip=s"  );
$config->define( "data_lmonth_hexcode=s"  );
$config->define( "data_lmonth_multiply=s"  );
$config->define( "data_lmonth_measure=s"  );
$config->define( "data_lmonth_index=s"  );
$config->define( "data_lmonth_descr=s"  );
$config->define( "data_lmonth_flip=s"  );
$config->define( "data_iac_hexcode=s"  );
$config->define( "data_iac_multiply=s"  );
$config->define( "data_iac_measure=s"  );
$config->define( "data_iac_index=s"  );
$config->define( "data_iac_descr=s"  );
$config->define( "data_iac_flip=s"  );
$config->define( "data_vac_hexcode=s"  );
$config->define( "data_vac_multiply=s"  );
$config->define( "data_vac_measure=s"  );
$config->define( "data_vac_index=s"  );
$config->define( "data_vac_descr=s"  );
$config->define( "data_vac_flip=s"  );
$config->define( "data_fac_hexcode=s"  );
$config->define( "data_fac_multiply=s"  );
$config->define( "data_fac_measure=s"  );
$config->define( "data_fac_index=s"  );
$config->define( "data_fac_descr=s"  );
$config->define( "data_fac_flip=s"  );

# fill variables by reading configuration file
$config->file( "/home/pi/ginlong_poller_pvoutput/config.ini" ) || die "FAILED to open and/or read config file: config.ini\n";

if ($config->flags_debug) {
  print "debug=" . $config->flags_debug ;
  print ", hex_serial_length=" . $config->hex_serial_length . "\n" ;
}

#
# inverter data format codes (hash of hashes)
#
%HoH = (
	VPV1   => {
                HEXCODE  => $config->data_vpv1_hexcode,
                MULTIPLY => $config->data_vpv1_multiply,
                MEAS     => $config->data_vpv1_measure,
                INDEX    => $config->data_vpv1_index,
                VALUE    => 0,
                DESCR    => $config->data_vpv1_descr,
		FLIP     => $config->data_vpv1_flip,
	},
	VPV2   => {
                HEXCODE  => $config->data_vpv2_hexcode,
                MULTIPLY => $config->data_vpv2_multiply,
                MEAS     => $config->data_vpv2_measure,
                INDEX    => $config->data_vpv2_index,
                VALUE    => 0,
                DESCR    => $config->data_vpv2_descr,
                FLIP     => $config->data_vpv2_flip,
	},
	IPV1   => {
                HEXCODE  => $config->data_ipv1_hexcode,
                MULTIPLY => $config->data_ipv1_multiply,
                MEAS     => $config->data_ipv1_measure,
                INDEX    => $config->data_ipv1_index,
                VALUE    => 0,
                DESCR    => $config->data_ipv1_descr,
                FLIP     => $config->data_ipv1_flip,
	},
	IPV2   => {
                HEXCODE  => $config->data_ipv2_hexcode,
                MULTIPLY => $config->data_ipv2_multiply,
                MEAS     => $config->data_ipv2_measure,
                INDEX    => $config->data_ipv2_index,
                VALUE    => 0,
                FLIP     => $config->data_ipv2_flip,
                DESCR    => $config->data_ipv2_descr,
	},
	EMONTH => {
                HEXCODE  => $config->data_emonth_hexcode,
                MULTIPLY => $config->data_emonth_multiply,
                MEAS     => $config->data_emonth_measure,
                INDEX    => $config->data_emonth_index,
                VALUE    => 0,
                DESCR    => $config->data_emonth_descr,
		FLIP     => $config->data_emonth_flip,
	},
        LMONTH => {
                HEXCODE  => $config->data_lmonth_hexcode,
                MULTIPLY => $config->data_lmonth_multiply,
                MEAS     => $config->data_lmonth_measure,
                INDEX    => $config->data_lmonth_index,
                VALUE    => 0,
                DESCR    => $config->data_lmonth_descr,
                FLIP     => $config->data_lmonth_flip,
        },
	IAC    => {
                HEXCODE  => $config->data_iac_hexcode,
                MULTIPLY => $config->data_iac_multiply,
                MEAS     => $config->data_iac_measure,
                INDEX    => $config->data_iac_index,
                VALUE    => 0,
                DESCR    => $config->data_iac_descr,
                FLIP     => $config->data_iac_flip,
	},
	VAC    => {
                HEXCODE  => $config->data_vac_hexcode,
                MULTIPLY => $config->data_vac_multiply,
                MEAS     => $config->data_vac_measure,
                INDEX    => $config->data_vac_index,
                VALUE    => 0,
                DESCR    => $config->data_vac_descr,
                FLIP     => $config->data_vac_flip,
	},
	FAC    => {
                HEXCODE  => $config->data_fac_hexcode,
                MULTIPLY => $config->data_fac_multiply,
                MEAS     => $config->data_fac_measure,
                INDEX    => $config->data_fac_index,
                VALUE    => 0,
                DESCR    => $config->data_fac_descr,
                FLIP     => $config->data_fac_flip,
	},
); #end %HoH

#######################################################################
#
# Returns 1 (true) if Windows, 0 (false) if not (eg: Linux/Unix/Other)
#
sub isWindows() {
   if ( $^O eq 'cygwin' || $^O =~ /^MSWin/ ) {
      return 1;
   }
   return 0;
} #end isWindows

#######################################################################
#
# Open serial/usb/bluetooth port depending on Operating System
#
sub initialiseSerialPort() {
  if ($config->flags_debug) {
    print "Initialise Serial Port... ";
  }
  if ( &isWindows() ) {      # Windows (ActivePerl)
    eval "use Win32::SerialPort";
    $port = $ARGV[0] || $config->serial_port_win;

    # Open the serial port
    $serial = Win32::SerialPort->new ($port, 0, '') || die "Can\'t open $port: $!";
  }
  else {				     # Unix/Linux/other
    eval "use Device::SerialPort";
    $port = $ARGV[0] || $config->serial_port_oth;

    # Open the serial port
    $serial = Device::SerialPort->new ($port, 0, '') || die "Can\'t open $port: $!";
  }
  if ($config->flags_debug) {
    print "port = $port\n";
  }

  #
  # Open the serial port
  #
  $serial->error_msg(1); 		# use built-in hardware error messages like "Framing Error"
  $serial->user_msg(1);			# use built-in function messages like "Waiting for ..."
  $serial->baudrate($config->serial_baud) || die 'fail setting baudrate, try -b option';
  $serial->parity($config->serial_parity) || die 'fail setting parity';
  $serial->databits($config->serial_databits) || die 'fail setting databits';
  $serial->stopbits($config->serial_stopbits) || die 'fail setting stopbits';
  $serial->handshake($config->serial_handshake) || die 'fail setting handshake';
  $serial->datatype($config->serial_datatype) || die 'fail setting datatype';
  $serial->write_settings || die 'could not write settings';
  $serial->read_char_time(0);     	# don't wait for each character
  $serial->read_const_time(1000); 	# 1 second per unfulfilled "read" call
} #end initialiseSerialPort

#######################################################################
#
# Close serial/usb/bluetooth port
#
sub closeSerialPort() {
    $serial->close || warn "*** WARNING Close port failed, connection may have died.\n";
    undef $serial;
} #end closeSerialPort

#######################################################################
#
# Trim function to remove whitespace from start and end of a string
#
sub trim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
} #end trim

#######################################################################
#
# Turn raw data from the inverter into a hex string
#
sub convRawToHex() {
  my $pstring = shift;
  my $hstring = unpack ("H*",$pstring);
  return $hstring;
} #end convRawToHex

#######################################################################
#
# Turn hex string into raw data for transmission to the inverter
#
sub convHexToRaw() {
  my $hstring = shift;
  my $pstring = pack (qq{H*},qq{$hstring});
  return $pstring;
} #end convHexToRaw

#######################################################################
#
# Write to the port (the inverter is on) & warn if it fails
#
sub writeToPort() {
  my $writeStr = shift;
  my $countOut = $serial->write($writeStr);
  warn "*** write failed ( $countOut ) ***\n" unless ($countOut);
  warn "*** write incomplete ( $countOut ) ***\n" if ( $countOut != length($writeStr) );
  return $countOut;
} #end writeToPort

#######################################################################
#
# Write to serial port then read result from buffer
# until expected read response received or timeout exceeded
#
sub writeReadBuffer() {
  my $writeString = shift;
  my $readPattern = shift;
  my $chars=0;
  my $buffer="";
  my $buffer2="x";
  my $timeout = $config->secs_timeout;

  if ($config->flags_debug) {
    print "writeReadBuffer: writeString=$writeString\n";
    print "writeReadBuffer: readPattern=$readPattern\n";
  }

  #
  # Write to (Serial) Port
  #
  &writeToPort(&convHexToRaw($writeString));

  # sleep for dodgy cables (eg beginner soldering or usb converters)
  # sleep 2;

  #
  # Read response from buffer until either expected response received or timeout reached
  #
  while ( $timeout > 0 ) {

    my ($countIn,$stringIn) = $serial->read(255); 		# will read _up to_ 255 chars
    if ($countIn > 0) {

      if ($config->flags_debug) {
        print "writeReadBuffer: saw..." . &convRawToHex($stringIn) . "\n";
      }

      $chars += $countIn;
      $buffer .= $stringIn;
      $hexBuffer = &convRawToHex($buffer);

      #
      # Check to see if expected read response is in the $buffer
      #
      if ( $hexBuffer =~ /$readPattern/ ) {
        ($buffer2) = ( $hexBuffer =~ /($readPattern.*$)/ );
        if ($config->flags_debug) {
          print "writeReadBuffer: found=$buffer2\n";
          print "Recv <- $buffer2 \n";
        }
        return $buffer2;
      }

    }
    else {
      $timeout--;
    }

  }	# end of while loop

  #
  # timeout was reached
  #
  $noTalks++;
  if ($config->flags_debug) {
    print "Waited " . $config->secs_timeout . " seconds and never saw $readPattern\n";
    print "noTalks=$noTalks, reInits=$reInits.\n";
  }

  #
  # Reset number of noTalks & attempt ReInit
  #
  if ( $noTalks > 0 ) {
    &closeSerialPort();
    #
    # check if reinitialise port timeout was reached, if so die
    #
    if ($config->secs_reinit >= 0 && $reInits > $config->secs_reinit) {
      die "REINIT MAX exceeded, aborted.\n";
    }

    #
    # Sleep until next time data needs to be polled (per $config->secs_datapoll_freq)
    #
    #&sleepTilNextPoll();

    #
    # Attempt to Re-initialise
    #
    $noTalks = 0;
    $reInits++;
    if ($config->flags_debug) {
      print "Re-Init attempt $reInits...\n";
    }
    &main();
  }
  
  return "";
} #end writeReadBuffer

#######################################################################
#
# Parse Data Format
# based on $HoH{HEXCODE} & store index/position in $HoH{INDEX}
#
sub parseDataFmt() {
  print "* Data Format:\n";
  my $hexData = shift;
  if ($hexData eq "") {
    print "n/a\n";
    return;
  }

  # split hex string into an array of 2char hex strings
  @d = ( $hexData =~ m/..?/g );

  my $dataOffset = $config->hex_data_to_follow_index + 1;
  my $dataToFollow = hex($d[$config->hex_data_to_follow_index]);
  print "dataToFollow = hex($d[$config->hex_data_to_follow_index]) = $dataToFollow\n";

  my $i = 0;
  for $x ($dataOffset .. $dataOffset + $dataToFollow - 1) {
    printf "%2s = %2s", $x, $d[$x] ;
    for $key ( keys ( %HoH ) ) {
      if ( $HoH{$key}{HEXCODE} eq $d[$x]) {
        $HoH{$key}{INDEX} = $i;
        printf " = %-8s = %2s = %s", $key, $HoH{$key}{INDEX}, $HoH{$key}{DESCR} ;
      }
    }
    print "\n";
    $i++;
  }
} #end parseDataFmt

#######################################################################
#
# Parse Data
# based on $HoH{INDEX} & store value in $HoH{VALUE}
#
sub parseData() {
  if ($config->flags_debug) {
    print "* Data:\n";
  }
  my $hexData = shift;
  #print "hexData: $hexData\n";
  if ($config->flags_debug) {
	print Dumper($hexData);
  }
  my $dataToFollow = hex( substr( $hexData, $config->hex_data_to_follow_index*3, 3 ) );
  if ($config->flags_debug) {
	print "* Data to follow:\n";
	print Dumper($config->hex_data_to_follow_index);
        print Dumper($dataToFollow);
  }
  #print "dataToFollow: $dataToFollow\n";
  my $startIndex = ( $config->hex_data_to_follow_index + 1 )*2;
  if ($config->flags_debug) {
	print "* startIndex:\n";
        print Dumper($startIndex);
  }
  #print "startIndex: $startIndex\n";
  my $numOfChars = $dataToFollow * 2;
  if ($config->flags_debug) {
	print "* numOfChars:\n";
        print Dumper($numOfChars);
  }
  #print "numOfChars: $numOfChars\n";
  my $data = substr( $hexData, $startIndex, $numOfChars );
  #print "data: $data\n";
  my $lastEmonth = $HoH{EMONTH}{VALUE};
  if ($config->flags_debug) {
	print "* Data: \n";
	print Dumper($data); 
  }
  # split hex string into an array of 4char hex strings
  @d = ( $data =~ m/..?.?.?/g );
  # split hex string into an array of 2char hex strings so we can get this and last months energy totals
  @e = ( $data =~ m/..?/g );

  my $finalOutput="";

  if ($config->flags_debug) {
	print "* emonth data\n";
	print Dumper($HoH{EMONTH});
  }

  # display data values - sort %HoH by INDEX
  for $key ( sort {$HoH{$a}{INDEX} <=> $HoH{$b}{INDEX} } keys ( %HoH ) ) {
       if ( $HoH{$key}{INDEX} ne "-1" ) {
         # Ginlong inverters need some of the hex strings flipped, eg 4b2c becomes 2c4b
         if ( $HoH{$key}{FLIP} eq "1" ) {
           $HoH{$key}{VALUE} = hex( join '', reverse split /(..)/, $d[$HoH{$key}{INDEX}] ) * $HoH{$key}{MULTIPLY};
         } else {
		if (($HoH{EMONTH})||($HoH{LMONTH})) {
			$HoH{$key}{VALUE} = hex( (($e[$HoH{$key}{INDEX}+1] )).(( $e[$HoH{$key}{INDEX}] ) ));
		} else {
	        	$HoH{$key}{VALUE} = hex( $d[$HoH{$key}{INDEX}] ) * $HoH{$key}{MULTIPLY};
		}
         }

	 if ($config->flags_pvoutput) {
	 	 #do nothing here
	 } else {
	        #printf " %s:%s", $key, $HoH{$key}{VALUE}, $HoH{$key}{MEAS} ;
		$finalOutput .= $key.":".$HoH{$key}{VALUE}." ";
		#$tmpkey = $HoH{$key}{DESCR};
		#$tmpkey =~ s/\s*//g;
		#$finalOutput .= $tmpkey." ".$HoH{$key}{VALUE}."\n";
	 }
       }
  }
  #my $wattage = "Wattage ". $HoH{VAC}{VALUE} * $HoH{IAC}{VALUE};
  my $wattage = $HoH{VAC}{VALUE} * $HoH{IAC}{VALUE};
  if ($config->flags_pvoutput) {
  	my $watthours = $HoH{EMONTH}{VALUE} * 1000;
	my $date = (strftime "%Y%m%d", localtime);
	my $time = (strftime "%H:%M", localtime);
	my $ua = LWP::UserAgent->new;
	$ua->default_header(
         "X-Pvoutput-Apikey"   => $config->flags_pvoutputkey,
         "X-Pvoutput-SystemId" => $config->flags_pvoutputid,
         "Content-Type"        => "application/x-www-form-urlencoded"
      	);
	#my $pvdata = "data=".(strftime "%Y%m%d", localtime).",".$wattage;
	#my $pvdata = "d=".(strftime "%Y%m%d", localtime).",t=".(strftime "%H:%M", localtime).",v1=".$watthours.",v2=".$wattage.",c1=1";
	my $request = POST LIVE_DATA_URL, [ d => $date, t => $time, v1 => $watthours, v2 => $wattage, c1 => "1" ];
	#my $pvdata = "data=".(strftime "%Y%m%d", localtime).",".(strftime "%H:%M", localtime).",".$watthours.",".$wattage."&".$cumulative;
  	#we're using curl to send the data to pvoutput
	my $res = $ua->request($request);
	#my $curl = WWW::Curl::Easy->new;
	#$curl->setopt(CURLOPT_HEADER,1);
	#$curl->setopt(CURLOPT_HTTPHEADER, ["X-Pvoutput-Apikey: ".$config->flags_pvoutputkey , "X-Pvoutput-SystemId: ".$config->flags_pvoutputid] );
	#$curl->setopt(CURLOPT_POST,1);
	#$curl->setopt(CURLOPT_POSTFIELDS,$pvdata);
	#$curl->setopt(CURLOPT_URL, 'http://pvoutput.org/service/r2/addoutput.jsp');
	#$curl->setopt(CURLOPT_URL, 'http://pvoutput.org/service/r2/addstatus.jsp');
	if ($config->flags_debug) {
		#$curl->setopt(CURLOPT_VERBOSE,1);
		#printf $pvdata;
		print "Sending to PVOUTPUT [ d => ".$date.", t => ".$time.", v1 => ".$watthours.", v2 => ".$wattage.", c1 => 1 ]\n";
	}
	# Starts the actual request
        #my $retcode = $curl->perform;
	#if ($retcode == 0) {
	#	print("Transfer went ok\n");
        #        my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
	#} else {
                # Error code, type of error, error message
        #        print("An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	#}
      	if (! $res->is_success) {
         die "Error via pvoutput.org: " . $res->content . "\n";
         #die "Couldn't submit data to pvoutput.org: " . $res->status_line . "\n";
     	}
  } else {
  	#printf " WAC:%s", $wattage ;
	$finalOutput .= "WAC:".$wattage;
	#$finalOutput .= $wattage."\n";
	printf $finalOutput;
	#my $outputfilesolar="/usr/local/bin/solar_poller_output";
	#if (($HoH{VAC}{VALUE}!=0)&&($HoH{IAC}{VALUE}!=0)&&($HoH{LMONTH}{VALUE}!=0)&&($HoH{EMONTH}{VALUE}!=0)) {
	#	open(FILE, ">$outputfilesolar");
	#	print FILE $finalOutput;
	#	close FILE;
	#}
	
  }

} #end parseData


#######################################################################
#
# MAIN METHOD
#
sub main() {
     #
     # Initialise Serial Port
     #
     &initialiseSerialPort();

     #print "Send -> req data as at " . &getDateTime() . " : " . $config->sendhex_data . "\n";
     $hexResponse = &writeReadBuffer($config->sendhex_data,$config->recvhex_data);
     &parseData($hexResponse) if ($hexResponse ne "");

} #end main

#######################################################################

&main();
