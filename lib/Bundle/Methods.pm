package Bundle::Methods;
use strict;
use warnings;
use parent qw(MyBase::Bio::Root::Root);
use Data::Dumper;
use IPC::Run;
use MyBase::Mysub;
use String::Random;
use B qw( svref_2object );
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw#can_run#;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    $self->setMethod("threads"=>5);
    $self->setMethod("chunk_size"=>1);
    return $self;
}


sub time_string
{
    my $self = shift;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
    return sprintf('%04d-%02d-%02d %02d:%02d:%02d',
		   $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

sub test_file{
    my $self = shift;
    my @file = @_;
    my $flag;
    foreach (@file){
	if (-e $_){ print STDERR "TEST: $_ existed\n"; $flag=1;}
	else {print STDERR "TEST: $_ not existed\n";return 0;}
    }
    return $flag;
}

sub test_rlt_file{

    my @file = @_;
    my $flag;
    foreach (@file){
	if (-e $_){ print STDERR "TEST: $_ existed\n"; $flag=1;}
	else {print STDERR "TEST: $_ not existed\n";return 0;}
    }
    return $flag;
}


sub time_elapse_string
{
    my ($self,$start_time, $end_time) = @_;
    my $elapsed_time = $end_time - $start_time;
    my $time_elapse_text = '';
    if ($elapsed_time >= 86400) {
	$time_elapse_text .= int($elapsed_time / 86400) . 'd ';
	$elapsed_time %= 86400;
    }
    if ($time_elapse_text or $elapsed_time >= 3600) {
	$time_elapse_text .= int($elapsed_time / 3600) . 'h ';
	$elapsed_time %= 3600;
    }
    if ($time_elapse_text or $elapsed_time >= 60) {
	$time_elapse_text .= int($elapsed_time / 60) . 'm ';
	$elapsed_time %= 60;
    }
    if ($time_elapse_text eq '' or $elapsed_time > 0) {
	$time_elapse_text .= $elapsed_time . 's ';
    }
    $time_elapse_text =~ s/\s$//g;
    return $time_elapse_text;
}

sub cmd_go{
    my ($self,$cmd,$fh,$ignore) =@_;
    $fh=*STDERR, if !$fh;
    print $fh "CMD: $cmd\n";
    my $start_time = time;
    print $fh "TIME: Starts at " . time_string($start_time) . "\n";
    my $hash=$self->system_bash($cmd);
    $hash->{success}=$?;
    $hash->{cmd}=$cmd;

    if($hash->{success}){$self->clean_err_output;if(!$ignore){die "not sucessfull: $hash->{stderr}\n";}else{warn("not sucessfull: $hash->{stderr}\n")}}
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    $self->time_string($end_time), $self->time_elapse_string($start_time, $end_time);
    return $hash;
}

sub cmd_go_nolog{
    my ($self,$cmd,$fh,$ignore) =@_;
    $fh=*STDOUT, if !$fh;
    print $fh "CMD: $cmd\n";
    my $start_time = time;
    print $fh "TIME: Starts at " . time_string($start_time) . "\n";
    my $hash=$self->system_bash($cmd);
    $hash->{success}=$?;
    $hash->{cmd}=$cmd;

    if($hash->{success}){$self->clean_err_output;if(!$ignore){die "not sucessfull: $hash->{stderr}\n";}else{warn("not sucessfull: $hash->{stderr}\n")}}
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    $self->time_string($end_time), $self->time_elapse_string($start_time, $end_time);
    return $hash;
}


sub clean_err_output{
    my ($self )=shift;
    foreach (keys %{$self->{_output}}){
	my $cmd = "rm $_";
	$self->system_bash($cmd);
    }
}

sub step_print{
    my ($self,$str)= @_;
    print STDERR "\nSTEP: $str\n";
}

sub system_bash {
    my $self = shift;
    my ($in,$stdout,$stderr);
    my @args = ("bash", "-c", shift );
    my $hash;
    IPC::Run::run \@args,\$in,\$hash->{stdout},\$hash->{stderr};
    #print $err;
    #print Dumper($stdout);
    #print Dumper($stderr);
    
    return $hash;
}


sub run{
    my($self,$cmd)=@_;
    my $fh_log=$self->log_fh();
    print {$fh_log->{cmd}} $cmd."\n";

    $self->isrun? my $out=$self->cmd_go($cmd):print STDERR "SKIP: $cmd\n";

    #print Dumper $self;
    if($out){
	print {$fh_log->{out}} "CMD:$out->{cmd}\nOUT:$out->{stdout}\n";
	print {$fh_log->{err}} "CMD:$out->{cmd}\nERR:$out->{stderr}\n";        
    }
    $out

}

sub log_last{
    my($self)=@_;
    #print Dumper($self);
    $self->system_bash("rm -rf ${$self->opt}{dir_log}/last"), if -e "`${$self->opt}{dir_log}/last";
    $self->mkdir("${$self->opt}{dir_log}/last");
    $self->system_bash("cp ${$self->opt}{dir_log_cmd}/* ${$self->opt}{dir_log}/last"), if exists ${$self->opt}{dir_log_cmd};
}

sub log_fh{
    my($self)=@_;
    #print Dumper($self->opt);
    $self->throw("Must include \$opt{time}=Bundle::Wrapper->date in script;"), if !${$self->opt}{time};
    
    my $string_gen = String::Random->new;
    ${$self->opt}{dir_log_cmd}=${$self->opt}{dir_log}."/${$self->opt}{time}"."-". $string_gen->randpattern("CCCCCCCC"), if !${$self->opt}{dir_log_cmd};
    $self->system_bash("mkdir -p ${$self->opt}{dir_log_cmd}");
    my @caller=caller(2);
    my $fh;
    $caller[3]=~s/.*://g;

    ## print Dumper ${$self->opt}{dir_log_cmd}."/".$caller[3].".cmd";
    open $fh->{cmd},">>",${$self->opt}{dir_log_cmd}."/".$caller[3].".cmd" or die "Can't open \$fh->{cmd}";
    open $fh->{out},">>",${$self->opt}{dir_log_cmd}."/".$caller[3].".out";
    open $fh->{err},">>",${$self->opt}{dir_log_cmd}."/".$caller[3].".err";
    return ($fh);
}

sub log_print{
    my($self,$cmd,$fh_log);
    if(!$fh_log){return "0";}
    if(ref($cmd) eq "ARRAY"){
	print $fh_log join ("\n",@$cmd)."\n";
    }
    elsif(ref($cmd) eq "SCALAR"){
	print $fh_log $cmd."\n";
    }
    else{
	$self->throw("wrong format log print")
    }
    
}

sub date{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my @abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @abbr_num = qw(01 02 03 04 05 06 07 08 09 10 11 12);
    $year += 1900;
    $mon  += 1;
    my @out;
    push @out,(sprintf("%s%02d%02d",$year,$mon,$mday),sprintf("%02d%02d%02d",$hour,$min,$sec));
    return join "-",@out;
}


sub mkdir{
    my ($self)=shift;
    my @dir = @_;
    foreach(@dir){
	my $cmd = "mkdir -p $_";
	if(! -e $_ ){
	    $self->cmd_go_nolog("$cmd",*STDOUT,1);
	}
	else{
	    if(-d $_){ print STDERR "SKIP: $cmd\n";}
	    else{$self->throw("existed a file name called $_");}
	}
    }
}

sub mkpath{
    my ($self)=shift;
    my @dir = @_;
    foreach(@dir){
	if(! -e $_ ){
	    $self->make_path($_);
	}
	else{
	    if(-d $_){ print STDERR "SKIP: mkdir $_\n";}
	    else{$self->throw("existed a file name called $_");}
	}
    }
}


sub getPrefix{
    my ($self,$str,$del)=@_;
    if(! defined $del){
	$del = "\\.\\w+?"
    }
    ## print Dumper $del;
    $str=~s/$del$//g;
    ## print Dumper $str;
    $str=~s/.*\///g;
    return $str;
}

sub getFilename{
    my ($self,$str)=@_;
    $str=~s/.*\///g;
    return $str;
}

sub getFiledir{
    my ($self,$str)=@_;

    if($str!~/\//){
	$str="./"
    }else{
	$str=~s/(.*\/).*/$1/g;
    }
    return $str;

}



sub getSub {
    my ($self,$pkg_name) = @_;
    my $pkg = do { no strict 'refs'; \%{ $pkg_name . '::' } };
    my $sub;
    my @sub;
    #print Dumper $pkg;
    foreach my $name (keys %$pkg) {
	#print Dumper $name;
	if(defined &{"main::$name"}){
	    #print Dumper $name;
	    my $glob = $pkg->{$name};
	    my $code = *$glob{CODE}
	    or next;
	    my $cv = svref_2object($code);
	    my $orig_pkg_name = $cv->GV->STASH->NAME;
	    next if $orig_pkg_name ne "main" || $name=~/^_/;
	    push @sub,$name;
	    #print Dumper $orig_pkg_name;
	}
	
    }
    $sub = join ",",@sub;
    return $sub
}


sub clean{
    my ($self,@dir)=@_;
    foreach (@dir){
	if(-e $_){
	    $self->step_print("rm file/dir in $_");
	    my $cmd="rm -rf $_";
	    $self->cmd_go($cmd);
	}
    }
}


1;

