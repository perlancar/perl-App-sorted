package App::sorted;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Sort::Sub ();

our %SPEC;

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

$SPEC{sorted} = {
    v => 1.1,
    summary => 'Check if lines of a file are sorted',
    description => <<'_',

Assuming `file.txt`'s content is:

    1
    2
    3

These will return success:

    % sorted file.txt
    % sorted -S numerically file.txt

But these will not:

    % sorted -S 'numerically<r>' file.txt
    % sorted -S 'asciibetically<r>' file.txt

Another example, assuming `file.txt`'s content is:

    1
    zz
    AAA
    cccc

then this will return success:

    % sorted -S by_length file.txt

while this will not:

    % sorted file.txt
    % sorted -S 'asciibetically<i>' file.txt

_
    args => {
        file => {
            schema => 'filename*',
            default => '-',
            pos => 0,
        },
        %Sort::Sub::argopts_sortsub,
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
};
sub sorted {
    my %args = @_;

    my $fh;
    if ($args{file} eq '-') {
        $fh = *STDIN;
    } else {
        open $fh, "<", $args{file}
            or return [500, "Can't open '$args{file}': $!"];
    }

    my $sort_sub  = $args{sort_sub}  // 'asciibetically';
    my $sort_args = $args{sort_args} // {};
    my $cmp = Sort::Sub::get_sorter($sort_sub, $sort_args);

    my $sorted = 1;
    my ($prev_line, $cur_line);
    my $line_num = 0;
    while (defined (my $cur_line = <$fh>)) {
        $line_num++;
        unless (defined $prev_line) {
            $prev_line = $cur_line;
            next;
        }
        if ($cmp->($prev_line, $cur_line) > 0) {
            $sorted = 0;
            last;
        }
        $prev_line = $cur_line;
    }

    my $msg = "File is ".($sorted ? "" : "NOT ")."sorted";
    [
        200,
        "OK",
        $msg,
        {
            'cmdline.exit_code' => $sorted ? 0:1,
            ($args{quiet} ? ('cmdline.result' => '') : ()),
            'func.line_num' => $line_num,
            'func.line1' => $prev_line,,
            'func.line2' => $cur_line,
        },
    ];
}

1;
#ABSTRACT:

=head1 SYNOPSIS

See L<sorted>.


=head1 append:SEE ALSO

The B<sorted> script is inspired by, and an alternative for, L<is-sorted> from
L<File::IsSorted> by SHLOMIF. B<sorted> added the ability to use L<Sort::Sub>
routines.

L<Sort::Sub>
