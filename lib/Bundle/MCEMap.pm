package Bundle::MCEMap;
use strict;
use warnings;
use parent qw(Bundle::Bio::Root::Root);
use parent qw(Bundle::Methods);
use Data::Dumper;
use MCE::Map;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    return $self;
}

sub cmd_MCEMap{
    my ($self,$cmd,$fh) =@_;
    MCE::Map::init {
	chunk_size => 1, 
	max_workers => $self->threads
    };
    
    #print Dumper($cmd);
    $fh=*STDERR, if !$fh;
    my $start_time = time;
    print $fh "CMD: ".scalar(@$cmd)." cmd to be run\n";
    if(@$cmd<5){
	map { print $fh "CMD: Example $_\n";} @$cmd;
    }else{
	print $fh "CMD: Example $$cmd[0]\n";
    }
    print $fh "TIME: Starts at " . $self->time_string($start_time) . "\n";
    #print Dumper($$cmd[0]);
    my @out = mce_map {my $hash=$self->system_bash($_);$hash->{success}=$?;$hash->{cmd}=$_;return $hash;} @$cmd;
    #print Dumper(@out);
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    $self->time_string($end_time), $self->time_elapse_string($start_time, $end_time);
    return (\@out);
    
}

sub run_MCEMap{
    my($self,$cmd,$opt)=@_;
    my $fh_log = $self->log_fh();

    print {$fh_log->{cmd}} join ("\n",@$cmd)."\n";

    my $skipstr;
    if(@$cmd<5){
    	map { $skipstr.="SKIP: Example $_\n";} @$cmd;
    }else{
    	$skipstr="SKIP: Example $$cmd[0]\n";
    }

    
    $self->isrun? my $out=$self->cmd_MCEMap($cmd):print STDERR "$skipstr\n";

    #print Dumper($out);
    if($out){
    	foreach (@$out){
    	    print {$fh_log->{out}} "CMD:$_->{cmd}\nOUT:$_->{stdout}\n";
    	    print {$fh_log->{err}} "CMD:$_->{cmd}\nERR:$_->{stderr}\n";
    	}
    }
    $out;
}


1;
