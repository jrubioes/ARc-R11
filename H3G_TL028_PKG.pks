CREATE OR REPLACE PACKAGE APPS.H3G_TL028_PKG IS
--
--+============================================================================+
--|                           Con.Nexo (Italy)                                 |
--|                            Milano, Italia                                  |
--+============================================================================+
--|                                                                            |
--| Description: Ricariche automatiche SDD da SOA                              |
--|                                                                            |
--|                                                                            |
--| Modification History:                                                      |
--| -----------------------                                                    |
--|                                                                            |
--| Author             Date       Version Remarks                              |
--| ------------------ ---------- ------- -------------------------------------|
--| L.Sinatra          25-02-2016 1.0     CR 28503                             |
--+============================================================================+
--
PROCEDURE estraz_ric_sdd
(
    errbuff            OUT VARCHAR2
  , errcode            OUT NUMBER
);
--
PROCEDURE delete_ric_soa_sdd
(
    errbuff             OUT VARCHAR2
  , errcode             OUT NUMBER
  , p_mesi_soa          IN  NUMBER
  , p_mesi_sdd          IN  NUMBER
);
--
PROCEDURE report_errori
(  x_errbuff           OUT  VARCHAR2
 , x_errcode           OUT  NUMBER
 , p_nome_pgm          IN   VARCHAR2
 , p_ente              IN   VARCHAR2
);
--
END H3G_TL028_PKG;
/

