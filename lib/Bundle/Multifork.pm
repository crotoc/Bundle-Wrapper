package Bundle::Multifork;
use strict;
use MCE::Hobo;
use MCE::Shared;
use warnings;
use base qw(Bundle::Bio::Root::Root);
use base qw(Bundle::Methods);
use Data::Dumper;
use IPC::Run;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    return $self;
}

sub cmd_multifork{
    my ($self,$cmd,$fh) =@_;
    
    $fh=*STDERR, if !$fh;
    my $start_time = time;
    print $fh "CMD: ".scalar(@$cmd)." cmd to be run\n";
    if(@$cmd<5){
	map { print $fh "CMD: Example $_\n";} @$cmd;
    }else{
	print $fh "CMD: Example $$cmd[0]\n";
    }
    print $fh "TIME: Starts at " . $self->time_string($start_time) . "\n";
    my $out=$self->multifork($cmd);
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    $self->time_string($end_time), $self->time_elapse_string($start_time, $end_time);
    return $out;
}

sub run_multifork{
    my($self,$cmd,$opt)=@_;
    my $fh= $self->log_fh(), if ${$self->opt}{log} ;
    print {$fh->{cmd}} join ("\n",@$cmd)."\n" if ${$self->opt}{log} ;
    
    $self->isrun? my $out=$self->cmd_multifork($cmd):print "SKIP: Example: $$cmd[1]\n";

    if($out && ${$self->opt}{log}){
	map {
	    print {$fh->{out}} "CMD:$_->{cmd}\nOUT:$_->{stdout}\n";
	    print {$fh->{err}} "CMD:$_->{cmd}\nERR:$_->{stderr}\n";
	} @$out;
	    
    }

}


sub multifork()
{
    my ($self, $array) = @_;
    my $j=0;
    my $out = MCE::Shared->array();
    my $err = MCE::Shared->array();;
    #print Dumper(scalar(MCE::Hobo->list()));
    while($j<@$array){
      LABEL:
      	while((!defined scalar(MCE::Hobo->list()) || scalar(MCE::Hobo->list())<= $self->threads) && $j<@$array){
	    MCE::Hobo->create(sub {my $hash=$self->system_bash($$array[$j]);$hash->{cmd}=$$array[$j];$hash->{success}=$?;return $hash;});
	    $j++;
	    #print $j;
	}        
	while ( my $hobo = MCE::Hobo->waitone() ) {
	    my $hoboerr = $hobo->error();
	    my $res = $hobo->result();
	    my $pid = $hobo->pid();
	    $out->push($res);
            
	    $self->throw("CMD: $res->{cmd} $res->{stderr}"),if $res->{success};
	    $self->throw("$hoboerr"),if $hoboerr;
	    goto LABEL, if scalar(MCE::Hobo->list()) <= $self->threads && $j <@$array;
	}

    }
    #print Dumper(@$out);
    #print Dumper(@$err);
    return $out;
}


1;
