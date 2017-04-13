/******************************************************************************/
/*                                                                            */
/*  REPORT MODS FRAMEWORK - CREATE OVERLAY FROM STREAM FILE                   */
/*                                                                            */
/*  Copyright (C) 2004, 2017  Christopher F. Burns, Sr.                       */
/*  c/o GEMKO Information Group (http://www.gemko.com)                        */
/*                                                                            */
/*  This program is free software: you can redistribute it and/or modify      */
/*  it under the terms of the GNU General Public License as published by      */
/*  the Free Software Foundation, either version 3 of the License, or         */
/*  (at your option) any later version.                                       */
/*                                                                            */
/*  This program is distributed in the hope that it will be useful,           */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of            */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             */
/*  GNU General Public License for more details.                              */
/*                                                                            */
/*  You should have received a copy of the GNU General Public License         */
/*  along with this program.  If not, see <http://www.gnu.org/licenses/>.     */
/*                                                                            */
/******************************************************************************/

             CMD        PROMPT('Create Overlay From StreamFile')

             PARM       KWD(OVLNAME) TYPE(Q1) MIN(1) PROMPT('Overlay')

 Q1:         QUAL       TYPE(*NAME) MIN(1)
             QUAL       TYPE(*NAME) DFT(*CURLIB) SPCVAL((*CURLIB)) +
                          PROMPT('Library')

             PARM       KWD(SRCFILE) TYPE(Q2) MIN(0) PROMPT('Source file')

 Q2:         QUAL       TYPE(*NAME) DFT(QOVLSRC)
             QUAL       TYPE(*NAME) DFT(*LIBL) SPCVAL((*LIBL) (*CURLIB)) +
                          PROMPT('Library')

             PARM       KWD(IFSPATH) TYPE(*CHAR) LEN(256) MIN(1) +
                          PROMPT('IFS path of PRN file')

             PARM       KWD(REPLACE) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*YES) VALUES(*YES *NO) PROMPT('Replace +
                          overlay')

