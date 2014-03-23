package MyMooVim;

use strict;
use warnings;

use VimTools;

vim_func AllCaps => sub {
    vim_msg "Hello there!";
    $_ <<= uc $_ for vim_buffer->lines;
};

vim_func 'PostfixToggle',
    range => 1, 
    sub {
},


1;
