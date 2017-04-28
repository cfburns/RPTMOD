       //*******************************************************************************************
       //                                                                                          *
       // REPORT MODS FRAMEWORK - SERVER                                                           *
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

       ctl-opt
         dftactgrp(*no)
         option(*srcstmt:*nodebugio)
         debug
         alwnull(*usrctl);                                                   // normal control specs

       dcl-f rptmod     keyed usage(*input) rename(rptmod:rptmodr);          // report mods index
       dcl-f qatmsmtpa  keyed usage(*input);                                 // SMTP aliases
       dcl-f qatoctcpip keyed usage(*input) extfile('QUSRSYS/QATOCTCPIP');   // TCP/IP attributes
       dcl-f splfgrid disk usage(*input) rename(splfgrid:splfgridr) usropn;  // spooled file grid
       dcl-f qsysprt printer(132) usropn;                                    // modified output

       dcl-pr ApplyMods extpgm(quapgm);                                      // apply content mods
         grdptr pointer const;                                               // pointer to grid
         numpgs int(10) const;                                               // number of pages
         commarea like(RptModCom);                                           // communication area
       end-pr;                                                               // apply content mods

       dcl-pr rcvdta extpgm('QRCVDTAQ');                                     // receive data queue
         rddqnm char(10)  const;                                             // data queue name
         rddqlb char(10)  const;                                             // library name
         rdleng packed(5) const;                                             // length of data
         rddata like(type01);                                                // queue entry data
         rdwait packed(5) const;                                             // wait time
       end-pr;                                                               // receive data queue

       dcl-pr runoscmd extpgm('QCMDEXC');                                    // run o/s command
         cmdstrx like(cmdstr) const;                                         // command string
         cmdlenx like(cmdlen) const;                                         // command length
       end-pr;                                                               // run o/s command

       dcl-pr rtvsplfa extpgm('QUSRSPLA');                                   // retrieve splf attrib
         rsrecvx like(rsrecv);                                               // receiver variable
         rsrlenx like(rsrlen);                                               // receiver var length
         rsfmtnx like(rsfmtn);                                               // format name
         rsqjbnx like(rsqjbn);                                               // qualified job name
         rsinjbx like(rsinjb);                                               // internal job i/d
         rsinspx like(rsinsp);                                               // internal splf i/d
         rsspfnx like(rsspfn);                                               // spooled file name
         rsspnox like(rsspno);                                               // spooled file number
       end-pr;                                                               // retrieve splf attrib

       dcl-ds type01 len(128) qualified;                                     // type 01 format
         spljob char(26) pos(13);                                            // spooled file job
         jobnam char(10) pos(13);                                            // splf job name
         jobusr char(10) pos(23);                                            // splf job user
         jobnum char(6)  pos(33);                                            // splf job number
         splnam char(10) pos(39);                                            // spooled file name
         splnum int(10)  pos(49);                                            // spooled file number
       end-ds;                                                               // type 01 format

       dcl-ds rsrecv len(2048) qualified;                                    // QUSRSPLA receiver
         frmtyp char(10) pos(81);                                            // form type
         usrdta char(10) pos(91);                                            // user data
         numpag int(10)  pos(141);                                           // number of pages
         linper int(10)  pos(173);                                           // lines per inch
         chrper int(10)  pos(177);                                           // chars per inch
         outque char(10) pos(183);                                           // output queue name
         outlib char(10) pos(193);                                           // output queue library
         crtdat zoned(7) pos(203);                                           // creation date
         crttim zoned(6) pos(210);                                           // creation time
         crtpgm char(10) pos(236);                                           // creation program
         paglen int(10)  pos(425);                                           // page length
         pagwid int(10)  pos(429);                                           // page width
         ovflin int(10)  pos(437);                                           // overflow line
         fovlnm char(10) pos(729);                                           // front overlay name
         fovllb char(10) pos(739);                                           // front overlay libr
       end-ds;                                                               // QUSRSPLA receiver

       dcl-ds pgmsts psds qualified;                                         // program status d/s
         pgmnam *proc;                                                       // program name
         errmsg char(7)  pos(40);                                            // error message i/d
         pgmlib char(10) pos(81);                                            // program library
         jobnam char(10) pos(244);                                           // job/workstation name
         wrkstn char(10) pos(244);                                           // job/workstation name
         usrprf char(10) pos(254);                                           // user profile
         jobnum char(6)  pos(264);                                           // job number
       end-ds;                                                               // program status d/s

       dcl-ds Pages dim(1500) qualified based(PagPtr);                       // two dimension array
         Lines char(132) dim(66);                                            // ..of pages by lines
       end-ds;                                                               // two dimension array

       dcl-ds RptModCom;                                                     // communication area
         FormType char(10);                                                  // form type
         PDFName  varchar(64);                                               // PDF file name
         EmailAdr varchar(64);                                               // E-mail address
       end-ds;                                                               // communication area

       dcl-ds k_qatmsmtpa likerec(qtmsmpr:*key) inz;                         // key to qatmsmtpa

       dcl-s HecFreezesOvr ind;                                              // end of program flag
       dcl-s PagSiz packed(5);                                               // page size
       dcl-s OvlPos packed(5);                                               // overlay position
       dcl-s PagIdx packed(5);                                               // page index
       dcl-s LinIdx packed(5);                                               // line index
       dcl-s QuaPgm char(21);                                                // qualified pgm name
       dcl-s Domain varchar(64);                                             // system domain name
       dcl-s IFSPth varchar(256);                                            // IFS document path
       dcl-s OutLines int(10);                                               // num output lines

       dcl-s rsrlen int(10) inz(%len(rsrecv));                               // receiver var length
       dcl-s rsfmtn char(8) inz('SPLA0100');                                 // format name
       dcl-s rsqjbn char(26);                                                // qualified job name
       dcl-s rsinjb char(16);                                                // internal job i/d
       dcl-s rsinsp char(16);                                                // internal splf i/d
       dcl-s rsspfn char(10);                                                // spooled file name
       dcl-s rsspno int(10);                                                 // spooled file number

       dcl-s cmdstr char(512);                                               // command string
       dcl-s cmdlen packed(15:5) inz(%len(cmdstr));                          // command length

       dcl-c squote       x'7D';                                             // single quote

       //*******************************************************************************************
       //
       // Continuously poll data queue RPTMOD for spooled file notificiations.
       // When one arrives, check its identifiers against the rules in table
       // RPTMOD to see if there are any direct or wild card matches.  For
       // each match, perform the associated Transform Type (RMTYPE):
       //
       // F = FTP spooled file directly to a PDF capable printer.
       // P = Convert spooled file to a PDF in a specified IFS directory.
       // E = E-mail the spooled file to the SMTP alias in the original
       //       user's system distribution directory entry.

       dou HecFreezesOvr;                                                    // until 12th of never

         rcvdta('RPTMOD' : pgmsts.pgmlib : %len(type01) : type01 : -1);      // rcv dtaq entry

         rsqjbn = type01.spljob;                                             // qualified job name
         rsspfn = type01.splnam;                                             // spooled file name
         rsspno = type01.splnum;                                             // spooled file number

         monitor;                                                            // catch all errors
           rtvsplfa(rsrecv : rsrlen : rsfmtn : rsqjbn:
                    rsinjb : rsinsp : rsspfn : rsspno);                      // rtv splf attributes
         on-error *all;                                                      // on any error
           iter;                                                             // skip this spool file
         endmon;                                                             // catch all errors

         setll *loval rptmodr;                                               // set to top of file

         dou %eof(rptmod);                                                   // until no more rules
           read rptmodr;                                                     // get next mods match

           if rmenab = 'Y'
             and (rmfile = '*ALL' or rmfile = ' ' or rmfile = type01.splnam)
             and (rmapgm = '*ALL' or rmapgm = ' ' or rmapgm = rsrecv.usrdta
                                                  or rmapgm = rsrecv.crtpgm)
             and (rmsrcq = '*ALL' or rmsrcq = ' ' or rmsrcq = rsrecv.outque)
             and (rmsrcl = '*ALL' or rmsrcl = ' ' or rmsrcl = rsrecv.outlib)
             and (rmusrp = '*ALL' or rmusrp = ' ' or rmusrp = type01.jobusr)
             and (rmftyp = '*ALL' or rmftyp = ' ' or rmftyp = rsrecv.frmtyp)
             and not %eof(rptmod);                                           // if matching rule

             clear RptModCom;                                                // clear comm area

             if rmmpgm > *blanks and rmmlib > *blanks;                       // if modification pgm

               CreateGrid();                                                 // create splf grid

               quapgm = %trim(rmmlib) + '/' + %trim(rmmpgm);                 // qualified pgm name
               ApplyMods(PagPtr : rsrecv.numpag : RptModCom);                // apply content mods

               CreateSpool();                                                // create spooled file

             elseif rmtype = 'F';                                            // or ftp to printer

               FTPSpool();                                                   // FTP spooled file

               if rmdelt = 'Y';                                              // if delete after
                 DeleteSpool();                                              // delete spooled file
               endif;                                                        // if delete after

             elseif rmtype = 'E';                                            // or e-mailing

               EmailSpool();                                                 // e-mail spooled file

               if rmdelt = 'Y';                                              // if delete after
                 DeleteSpool();                                              // delete spooled file
               endif;                                                        // if delete after

             elseif rmtype = 'P';                                            // or create PDF

               BuildPDF();                                                   // build PDF file

               if rmdelt = 'Y';                                              // if delete after
                 DeleteSpool();                                              // delete spooled file
               endif;                                                        // if delete after

             elseif rmtrgq > *blanks;                                        // or redistributing

               CreateGrid();                                                 // create splf grid
               CreateSpool();                                                // create spooled file

               if rmdelt = 'Y';                                              // if delete after
                 DeleteSpool();                                              // delete spooled file
               endif;                                                        // if delete after

             endif;                                                          // if modification pgm
           endif;                                                            // if matching rule
         enddo;                                                              // until no more rules
       enddo;                                                                // until 12th of never

       return;                                                               // end of program


       //*******************************************************************************************

     oqsysprt   e            putpag            1                                go to next page
     o                       spltxt             132                             just reuse the field

     o          e            putlin         1                                   out 1 line at a time
     o                       spltxt             132                             just reuse the field

       //*******************************************************************************************
       //
       // Loads the content of the spooled file into a memory grid comprised
       // of lines within pages.  Skipped lines are honored and become
       // available to hold content.

       dcl-proc CreateGrid;                                                  // create splf grid

       cmdstr = 'CPYSPLF FILE(' + %trim(type01.splnam) + ') ' +
                'TOFILE(SPLFGRID) ' +
                'JOB(' + %trim(type01.jobnum) + '/' +
                         %trim(type01.jobusr) + '/' +
                         %trim(type01.jobnam) + ') ' +
                'SPLNBR(' + %char(type01.splnum) + ') ' +
                'MBROPT(*REPLACE) CTLCHAR(*PRTCTL)';                         // command string

       callp(e) runoscmd(cmdstr:cmdlen);                                     // run o/s command

       PagIdx = *zeros;
       LinIdx = *zeros;
       PagSiz = %size(Pages.Lines) * %elem(Pages.Lines);
       PagPtr = %alloc(PagSiz);

       open splfgrid;                                                        // open spool file grid

       dou %eof(splfgrid);                                                   // until end of splf
         read splfgridr;                                                     // read next splf line

         if not %eof(splfgrid);                                              // if not end of splf

           if PagIdx = 0 or skpbef > *blanks and %int(skpbef) <= LinIdx;     // if skip to next page
             PagIdx = PagIdx + 1;                                            // increment page index
             LinIdx = %int(skpbef);                                          // set line index
             PagPtr = %realloc(PagPtr:(PagIdx * PagSiz));                    // alloc grid space
             clear Pages(PagIDX);                                            // clear page area
           elseif skpbef > *blanks;                                          // if skip to line
             LinIdx = %int(skpbef);                                          // set line index
           else;                                                             // no skip before
             LinIdx = LinIdx + %int(spcbef);                                 // increment line index
           endif;                                                            // if skip before

           if spcbef = *zeros;                                               // if overlay line

             dou ovlpos = *zeros;                                            // until no more chars
               ovlpos = %check(' ':spltxt);                                  // 1st non blank posn

               if ovlpos > *zeros;                                           // if non blank char
                 %subst(Pages(PagIdx).Lines(LinIdx):ovlpos:1) =
                 %subst(spltxt:ovlpos:1);                                    // merge with prev line
                 %subst(spltxt:ovlpos:1) = ' ';                              // clear from curr line
               endif;                                                        // if non blank char

             enddo;                                                          // until no more chars

           else;                                                             // normal spaced line

             Pages(PagIdx).Lines(LinIdx) = spltxt;                           // insert line text

           endif;                                                            // if overlay line
         endif;                                                              // if not end of splf
       enddo;                                                                // until end of splf

       close splfgrid;                                                       // close grid file

       end-proc;                                                             // create splf grid

       //*******************************************************************************************
       //
       // Creates a new spooled file containg the contents of the memory grid,
       // with the attributes of the original spooled file and any overrides
       // specified in the RPTMOD rule record.

       dcl-proc CreateSpool;                                                 // create new splf

       dcl-s TargQual char(21);                                              // target que qualified

       if rmcopy < 1;                                                        // if no copies
         rmcopy = 1;                                                         // set to 1
       endif;                                                                // if no copies

       if rmtrgq = *blanks;                                                  // if no target outq
         TargQual = '*JOB';                                                  // use server job outq
       elseif rmtrgl = *blanks;                                              // or no target library
         TargQual = '*LIBL/' + rmtrgq;                                       // assume *LIBL
       else;                                                                 // outq & libr provided
         TargQual = %trim(rmtrgl) + '/' + rmtrgq;                            // qualified outq
       endif;                                                                // if no target outq

       if rmpglo > 0;                                                        // if page len override
         rsrecv.paglen = rmpglo;                                             // force page length
       endif;                                                                // if page len override

       if rmpgwo > 0;                                                        // if page wid override
         rsrecv.pagwid = rmpgwo;                                             // force page width
       endif;                                                                // if page wid override

       if rmlpio > 0;                                                        // if lin/inch override
         rsrecv.linper = rmlpio * 10;                                        // force lines per inch
       endif;                                                                // if lin/inch override

       if rmcpio > 0;                                                        // if chr/inch override
         rsrecv.chrper = rmcpio * 10;                                        // force chars per inch
       endif;                                                                // if chr/inch override

       if rmovfo > 0;                                                        // if overflow override
         rsrecv.ovflin = rmovfo;                                             // force overflow line
       endif;                                                                // if overflow override

       cmdstr = 'OVRPRTF FILE(QSYSPRT) ' +
                'SPLFNAME(' + %trim(type01.splnam)          + ') ' +
                'PAGESIZE(' + %char(rsrecv.paglen)          + ' '  +
                              %char(rsrecv.pagwid)          + ') ' +
                'LPI(' + %char(%int(rsrecv.linper / 10))    + ') ' +
                'CPI(' + %char(%int(rsrecv.chrper / 10))    + ') ' +
                'COPIES(' + %char(rmcopy)                   + ') ' +
                'OUTQ(' + %trim(TargQual)                   + ') ' +
                'PRTTXT(' + squote + %trim(rmrecp) + squote + ') ' +
                'USRDTA(' + squote + %trim(rsrecv.usrdta)
                          + squote                          + ') ' +
                'FORMTYPE(' + squote + %trim(rsrecv.frmtyp)
                            + squote                        + ') ' +
                'OVRFLW(' + %char(rsrecv.ovflin)            + ')';           // command string

       if rmtype = 'P' and PDFName > '';                                     // if creating PDF
         cmdstr = %trim(cmdstr) + ' DEVTYPE(*AFPDS) WSCST(*PDF) TOSTMF(' +
           squote + %trim(rmpath) + '/' + %trim(PDFName) + squote + ')';     // append OVRPRTF
       endif;                                                                // if creating PDF

       if rmtype = 'P' and PDFName <= '';                                    // if creating PDF
         cmdstr = %trim(cmdstr) + ' DEVTYPE(*AFPDS) WSCST(*PDF) TOSTMF(' +
           squote + %trim(rmpath) + '/' + %trim(type01.splnam) + '_' +
           %char(%timestamp) + '.pdf' + squote + ')';                        // append OVRPRTF
       endif;                                                                // if creating PDF

       if rmovnm = *blanks and rsrecv.fovlnm > *blanks;                      // if orig overlay
         rmovnm = rsrecv.fovlnm;                                             // use orig orverlay
         rmovlb = rsrecv.fovllb;                                             // use orig library
       endif;                                                                // if orig overlay

       if rmovnm > *blanks and rmovnm <> '*NONE';                            // if overlay

         if rmovlb = *blanks;                                                // if no library
           rmovlb = '*LIBL';                                                 // assume library list
         endif;                                                              // if no library

         cmdstr = %trim(cmdstr) + ' FRONTOVL(' + %trim(rmovlb) + '/'
                + %trim(rmovnm) + ')';                                       // add overlay clause

         if rmtype = 'S';                                                    // if creating spool
           cmdstr = %trim(cmdstr) + ' DEVTYPE(*AFPDS)';                      // make it AFPDS
         endif;                                                              // if creating spool

       endif;                                                                // if overlay

       if rmtype = 'S' and FormType > ' ';                                   // if form type
         cmdstr = %trim(cmdstr) + ' FORMTYPE(' + %trim(FormType) + ')';      // append OVRPRTF
       endif;                                                                // if creating PDF

       if rmtype = 'S' and rmdraw > '0';                                     // if drawer override
         cmdstr = %trim(cmdstr) + ' DRAWER(' + rmdraw + ')';                 // append OVRPRTF
       endif;                                                                // if drawer override

       callp(e) runoscmd(cmdstr:cmdlen);                                     // run o/s command

       open qsysprt;                                                         // open printer file

       if rsrecv.paglen > (%elem(Pages.Lines) - 1);                          // if too many lines
         OutLines = %elem(Pages.Lines) - 1 ;                                 // limit to array elem
       else;                                                                 // not too many lines
         OutLines = rsrecv.paglen;                                           // use orig line count
       endif;                                                                // if too many lines

       for PagIdx = 1 to rsrecv.numpag;                                      // for every page

         for LinIdx = 1 to OutLines;                                         // for every line
           spltxt = Pages(PagIdx).Lines(LinIdx);                             // entire cell of text
           except putlin;                                                    // write to printer
         endfor;                                                             // for every line

         if PagIdx < rsrecv.numpag;                                          // if more pages
           except putpag;                                                    // skip to next page
         endif;                                                              // if more pages

       endfor;                                                               // for every page

       close qsysprt;                                                        // close print file

       end-proc;                                                             // create new splf

       //*******************************************************************************************
       //
       // Simply creates a PDF in the specified IFS directory from an existing
       // spooled file, when no content modification is required.  If custom
       // PDF naming is required, write a modification handler to generate the
       // name, specify the name of that handler in the RPTMOD record, while
       // using the communications area to transport the PDF document name
       // back to this program.  In that case, CreateSpool is used instead of
       // this procedure.

       dcl-proc BuildPDF;                                                    // build PDF file

       dcl-s SpoolNumber zoned(6);                                           // spooled file number

       SpoolNumber = type01.splnum;                                          // spooled file number
       IFSPth      = %trim(rmpath) + '/';                                    // start of PDF name

       if rsrecv.usrdta > *blanks;                                           // if user data
         IFSPth += %trim(rsrecv.usrdta) + '_';                               // embed in name
       endif;                                                                // if user data

       IFSPth += %trim(type01.splnam) + '_' +
                 %editc(SpoolNumber:'X') + '_' +
                 %trim(type01.jobusr) + '_' +
                 %char(%date(rsrecv.crtdat:*cymd):*iso0) + '_' +
                 %char(%time(rsrecv.crttim:*hms):*hms0)  + '.pdf';           // rest of PDF name

       cmdstr = 'CPYTOSTMF FROMMBR(' + Squote + '/QSYS.LIB/' +
                %trim(pgmsts.pgmlib) + '.LIB/PCASCII.FILE/PCASCII.MBR' +
                Squote + ') ' +
                'TOSTMF(' + Squote + IFSPth + Squote + ') ' +
                'STMFOPT(*REPLACE) STMFCODPAG(*PCASCII)';                    // create ascii shell

       callp(e) runoscmd(cmdstr:cmdlen);                                     // run o/s command

       cmdstr = 'CPYSPLF FILE(' + %trim(type01.splnam) + ') ' +
                'TOFILE(*TOSTMF) ' +
                'JOB(' + %trim(type01.jobnum) + '/' +
                         %trim(type01.jobusr) + '/' +
                         %trim(type01.jobnam) + ') ' +
                'SPLNBR(' + %char(type01.splnum) + ') ' +
                'TOSTMF(' + Squote + IFSPth + Squote + ') ' +
                'WSCST(*PDF) ' +
                'STMFOPT(*REPLACE)';                                         // cpystmf command

       callp(e) runoscmd(cmdstr:cmdlen);                                     // run o/s command

       end-proc;                                                             // build PDF file

       //*******************************************************************************************
       //
       // Creates a PDF from an existing spooled file, then FTP's that PDF
       // file to a printer which supports the PDF Direct Print protocol,
       // and whose IP address and authentication has been suppled in the
       // RPTMOD rule record.

       dcl-proc FTPSpool;                                                    // FTP spooled file

       if rmftph > *blanks and rmftps > *blanks;                             // if FTP settings

         BuildPDF();                                                         // build PDF file

         cmdstr = 'CPY OBJ(' + sQuote + IFSPth + sQuote + ') '
                + 'TOOBJ('   + sQuote + %trim(rmpath) + '/'
                             + %trim(rmftph) + '.pdf' + sQuote + ') '
                + 'REPLACE(*YES)';                                           // IFS copy command

         callp(e) runoscmd(cmdstr:cmdlen);                                   // run o/s command

         cmdstr = 'OVRDBF FILE(INPUT) '
                + 'TOFILE(' + %trim(pgmsts.pgmlib) + '/QFTPSRC) '
                + 'MBR(' + %trim(rmftps) + ') '
                + 'OVRSCOPE(*CALLLVL)';                                      // OVRDBF command

         callp(e) runoscmd(cmdstr:cmdlen);                                   // run o/s command

         cmdstr = 'OVRDBF FILE(OUTPUT) '
                + 'TOFILE(' + %trim(pgmsts.pgmlib) + '/QFTPSRC) '
                + 'MBR(OUTPUT) '
                + 'OVRSCOPE(*CALLLVL)';                                      // OVRDBF command

         callp(e) runoscmd(cmdstr:cmdlen);                                   // run o/s command

         cmdstr = 'FTP RMTSYS(' + %trim(RMFTPH) + ')';                       // FTP launch command

         callp(e) runoscmd(cmdstr:cmdlen);                                   // run o/s command

       endif;                                                                // if FTP settings

       end-proc;                                                             // FTP spooled file

       //*******************************************************************************************
       //
       // Creates a PDF from an existing spooled file, then e-mails that PDF
       // file to the SMTP alias in the original user's system distribution
       // directory entry.  Command SNDSMTPEMM is used.

       dcl-proc EmailSpool;                                                  // email spooled file

       dcl-ds k_qatoctcpip likerec(qattr:*key) inz;                          // key to QATOCTCPIP

       BuildPDF();                                                           // command structure

       if rmmpgm > *blanks and EmailAdr > *blanks;                           // if address from mod
         rmmail = EmailAdr;                                                  // use that address
       endif;                                                                // if address from mod

       if rmmail <= *blanks;                                                 // if no e-mail addr

         k_qatmsmtpa.userid = type01.jobusr;                                 // user ID key
         chain %kds(k_qatmsmtpa:1) qtmsmpr;                                  // search qatmsmtpa

         if %found(qatmsmtpa);                                               // if smtp alias found

           rmmail = %trim(smtpuid) + '@' + %trim(domroute);                  // set user based addr

         else;                                                               // no smtp alias found

           k_qatoctcpip.keyword = 'LOCALDMNME';                              // domain name keyword
           chain %kds(k_qatoctcpip) qattr;                                   // search QATOCTCPIP

           if %found(qatoctcpip);                                            // if QATOCTCPIP
             Domain = %trim(%subst(Data:65:64));                             // extract domain name
             rmmail = %trim(type01.jobusr) + '@' + Domain;                   // build e-mail address
           endif;                                                            // if QATOCTCPIP

         endif;                                                              // if smtp alias found

       endif;                                                                // if no e-mail addr

       if rmmail > *blanks;                                                  // if e-mail address

         cmdstr = 'SNDSMTPEMM RCP((' + %trim(rmmail) + ')) ' +
                  'SUBJECT(' + Squote + 'Output from program ' +
                               %trim(rsrecv.crtpgm) + Squote +  ') ' +
                  'NOTE(' + SQuote + 'Attached.  ' +
                            %trim(%char(rsrecv.numpag)) +
                            ' pages.' + Squote + ') ' +
                  'ATTACH((' + Squote + IFSPth + Squote + ' *PDF))';         // command string

         callp(e) runoscmd(cmdstr:cmdlen);                                   // run o/s command

       endif;                                                                // if e-mail address

       end-proc;                                                             // email spooled file

       //*******************************************************************************************
       //
       // Simply deletes the spooled file identified in the data queue entry.
       // This is controlled by the Delete After flag in the RPTMOD rule record.
       // If executing multiple matching rules for the same spooled file, make
       // sure the rule specifying Delete After is the last one in sequence of
       // any possible matches, otherwise subsequent rules could fail.

       dcl-proc DeleteSpool;                                                 // delete spooled file

       cmdstr = 'DLTSPLF FILE(' + %trim(type01.splnam) + ') ' +
                'JOB(' + %trim(type01.jobnum) + '/' +
                         %trim(type01.jobusr) + '/' +
                         %trim(type01.jobnam) + ') ' +
                'SPLNBR(' + %char(type01.splnum) + ')';                      // build command

       monitor;                                                              // catch all errors
         callp(e) runoscmd(cmdstr:cmdlen);                                   // run o/s command
       on-error *all;                                                        // do nothing on error
       endmon;                                                               // catch all errors

       end-proc;                                                             // delete spooled file

       //*******************************************************************************************
