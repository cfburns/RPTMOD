       //*******************************************************************************************
       //                                                                                          *
       // REPORT MODS FRAMEWORK - SAMPLE MODIFICATION HANDLER                                      *
       //                                                                                          *
       // Copyright (C) 2004, 2017  Christopher F. Burns, Sr.                                      *
       //   c/o GEMKO Information Group (http://www.gemko.com)                                     *
       //                                                                                          *
       // This program is free software: you can redistribute it and/or modify                     *
       // it under the terms of the GNU General Public License as published by                     *
       // the Free Software Foundation, either version 3 of the License, or                        *
       // (at your option) any later version.                                                      *
       //                                                                                          *
       // This program is distributed in the hope that it will be useful,                          *
       // but WITHOUT ANY WARRANTY; without even the implied warranty of                           *
       // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                            *
       // GNU General Public License for more details.                                             *
       //                                                                                          *
       // You should have received a copy of the GNU General Public License                        *
       // along with this program.  If not, see <http://www.gnu.org/licenses/>.                    *
       //                                                                                          *
       //*******************************************************************************************

       // ASSUMPTIONS:
       //
       //   File OrdHdr is indexed by order number and has a field EntryUser
       //     (user who entered the order).
       //
       //   Purpose of handler is to add the Entry User column to an existing order report
       //     provided by 3rd party software, for which you have no source code.
       //
       //   Handler is called by server program RPTMOD, and the handler name is specified
       //     in the RPTMOD rule record.
       //
       //   Server program RPTMOD builds the 2-dimensional grid (pages by lines) of all
       //     content in the spooled file.  Unused print lines are available for content.
       //
       //   The Communication Area is not used in this example, but if you needed to
       //     generate the PDF file name from content in the spooled file, you could
       //     use it as RptModCom as a transport vehicle for it back to the server.
       //
       //   Report detail lines contain an order number in positions 7-11.  The order
       //     number always starts with a letter and there are no embedded blanks in
       //     an order number.  Positions 6 and 12 are always blank.  It has been
       //     determined that this is a reliable indication of a detail line.
       //     Identifying patterns in line formats is key to a successful mod handler.

       ctl-opt
         dftactgrp(*no);                                                     // req'd by PI

       dcl-pi *n;                                                            // entry parameters
         PagPtr pointer const;                                               // pointer to page grid
         NumPgs int(10) const;                                               // number of pages
         CommArea like(RptModCom);                                           // communication area
       end-pi;                                                               // entry parameters

       dcl-ds RptModCom;                                                     // communication area
         FormType char(10);                                                  // form type
         PDFName  varchar(64);                                               // PDF document name
         EmailAdr varchar(64);                                               // E-mail address
       end-ds;                                                               // communication area

       dcl-ds Pages dim(1500) qualified based(PagPtr);                       // page grid
         Lines char(132) dim(66);                                            // lines on page
       end-ds;                                                               // page grid

       dcl-f OrdHdr keyed;                                                   // order header

       dcl-s PagIdx int(5);                                                  // page dimension index
       dcl-s LinIdx int(5);                                                  // line dimension index
       dcl-s OrdKey like(OrdNum);                                            // key to OrdHdr

       For PagIdx = 1 to NumPgs;                                             // for each page

         %subst(Pages(PagIdx).Lines(3) : 123 : 5) = 'Entry';                 // insert column title
         %subst(Pages(PagIdx).Lines(4) : 123 : 4) = 'User';                  // insert column title

         For LinIdx = 1 to %elem(Pages.Lines);                               // for each line

           If %subst(Pages(PagIdx).Lines(LinIdx) :  6 : 1)  = ' ' and
              %subst(Pages(PagIdx).Lines(LinIdx) : 12 : 1)  = ' ' and
              %subst(Pages(PagIdx).Lines(LinIdx) :  7 : 1) >= 'A' and
              %subst(Pages(PagIdx).Lines(LinIdx) :  7 : 1) <= 'Z' and
              %scan(' ' : %subst(Pages(PagIdx).Lines(LinIdx) : 7 : 5)) = 0;  // if detail line

             OrdKey = %subst(Pages(PagIdx).Lines(LinIdx) : 7 : 5);           // key to OrdHdr
             Chain Ordkey OrdHdrRec;                                         // search OrdHdr

             If %found(OrdHdr);                                              // if OrdHdr match
               %subst(Pages(PagIdx).Lines(LinIdx) : 123 : 10) = EntryUser;   // insert user in line
             Endif;                                                          // if OrdHdr match

           Endif;                                                            // if detail line

         Endfor;                                                             // for each line

       Endfor;                                                               // for each page

       *inlr = *on;                                                          // end of program

