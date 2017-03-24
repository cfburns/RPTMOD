# RPTMOD
Report Mods Framework

The RMF is a simple spooled file processing and distribution engine for IBM i systems at releases 7.1 and higher.  It is not intended to be a come-all-end-all forms processing solution.  Rather it is designed to perform ordinary, everyday report distribution and archival tasks for small to mid sized businesses.  This includes duplication, routing to other queues, applying front side overlays, conversion to PDF and e-mail distribution of said PDFs.

One feature of the RMF (it's original feature, in fact) is the ability to actualy modify the spooled file content itself, through the use of a handler program containing standard snippets.  This allows companies running 3rd party ERP solutions to modify report formats without altering the source code (which can void support eligibility).

The RMF runs as an ILE-RPG based autostart job in a dedicated subsystem that is created during installation, along with a data queue that receives notifications from output queues of the user's choice.  See the Installation PDF for instructions.  The User Guide PDF explains how to add output queues to the monitor and how to populate the Rules Table (RPTMOD) to instruct the RMF how to handle the spooled files that either land in these output queues in RDY status, or change to RDY status from another status (such as HLD or SAV). 

Many commercial spooled file processing utilities are available for sale, but as with all packaged software, the end user only utilizes a tiny fraction of the functionality...while paying for 100% of it.  Obviously, that is not an issue with the RMF.  Neither is transferring the software to another serial number.  :-)

We encourage the IBM i development community to leverage this convenient little "engine that could" and help us expand it to meet the growing needs of small businesses.

Miscellaneous notes:

1. An maximum of 1500 pages at 66 lines per page, 132 columns is assumed, due to ILE-RPG data structure size limitiations.
2. No embedded SQL is used within the RPG, for the benefit of smaller shops that do not license the 5770-ST1 software option.
3. Multiple instances of the RMF within a single partition are allowed, however an output queue may only communicate with one at a time.
4. Most importantly...this is my first crack at GitHub...so go easy with the paddles !
