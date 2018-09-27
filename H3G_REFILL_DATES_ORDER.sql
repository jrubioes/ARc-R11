-- +==============================================================+
-- | MODULO                                                       |
-- |  <AR>                                                        |
-- | PROJECT                                                      |
-- |  AR_PGICO18  Importazione Ricariche ATM,CRM                  |
-- | REVISION                                                     |
-- |  1.2     07/09/2009                                          |
-- | AUTHOR                                                       |
-- |  25/11/02 Arata                 CREATED			  |
-- |           Sermidi               Functional Support           |
-- | DESCRIPTION                                                  |
-- |  <Allineamento Date in tabella d'interfaccia transazioni>    |
-- | INPUT                                                        |
-- |  SET OF BOOK ID = 1                                          |
-- | OUTPUT                                                       |
-- |  <none>                                                      |
-- | MODIFICATION HISTORY                                         |
-- |  11/12/2002    implementation                                |
-- |  10/04/2003    <change description : aggiunti casi 6,7 per   |
-- |                 gestione transazioni non presenti a          |
-- |                 sistema e raggruppamento per Sequenza <Arata>|
-- |  07/09/2009    tolta condizione cust_trx_type_name           |
-- |  01/10/2009    defect 74295                                  |
-- |  10/01/2014    CR26180
-- |  27/09/2018    Adapting sql to AR Cloud data model           |
-- +==============================================================+

set serveroutput ON SIZE 1000000

DECLARE
CURSOR c_trx_dates IS

SELECT DISTINCT
	   mx_int_lines.mx_trx_date DINT,
	   max_month.date_value DINT_MONTH,
	   cust_trx.mx_trx_date DSYS,
	   int_lines.trx_date DX,
	   TRUNC(mx_int_lines.mx_trx_date,'MONTH') MINT,
	   TRUNC(cust_trx.mx_trx_date,'MONTH') MSYS,
	   TRUNC(int_lines.trx_date,'MONTH') MX,
	   int_lines.trx_number TRX_NUMBER,
	   --int_lines.cust_trx_type_name TRX_TYPE, /* 10/04/2003 raggruppamento transazioni per sequenza */
	   mx_int_lines.doc_sequence_id TRX_SEQ

 FROM

	/* data + recente in interfaccia */
-- 	(
-- 	 SELECT int_lines.cust_trx_type_name,
-- 	 		MAX(int_lines.trx_date) mx_trx_date
-- 	 FROM ra_interface_lines_all int_lines
-- 	 WHERE int_lines.cust_trx_type_name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO')
-- 	 AND int_lines.batch_source_name = 'PMS_REFILL'
-- 	 group by int_lines.cust_trx_type_name
-- 	 ) mx_int_lines,

	 /* 10/04/2003 raggruppamento transazioni per sequenza */
	 (
	 SELECT  seqas.doc_sequence_id
	 		,MAX(int_lines.trx_date) mx_trx_date
	 FROM ra_interface_lines_all int_lines, fnd_doc_sequence_assignments seqas
	 WHERE 1=1 --mod 07/09/2009 defect 73657 -- int_lines.cust_trx_type_name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO')
	 AND int_lines.cust_trx_type_name=seqas.category_code
	 AND int_lines.batch_source_name = 'PMS_REFILL'
	 AND seqas.method_code='A'
	 AND seqas.set_of_books_id=1
	 AND SYSDATE >= seqas.start_date
	 AND (seqas.end_date IS NULL OR seqas.end_date>= SYSDATE)
	 GROUP BY  seqas.doc_sequence_id
	 ) mx_int_lines,

	/* data + recente a sys per ogni trx */

-- -- 	 (
-- 	 SELECT cust_trx_type.name  mx_trx_name, MAX(cust_trx.trx_date) mx_trx_date
-- 	 FROM ra_customer_trx_all cust_trx
-- 	 	  ,ra_cust_trx_types_all cust_trx_type
-- 	 WHERE cust_trx.cust_trx_type_id (+) = cust_trx_type.cust_trx_type_id
-- 	AND cust_trx_type.name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO')
-- --	 and 'RC-A-CRMO' = cust_trx_type.name
-- 	 GROUP BY cust_trx_type.name
-- -- 	 ) cust_trx,
--
	 /* data + recente a sys, 10/04/2003 raggruppamento transazioni per sequenza */
	(
	SELECT   seqas.doc_sequence_id
	 --,cust_trx_type.name  mx_trx_name
	 , MAX(cust_trx.trx_date) mx_trx_date
	 FROM ra_customer_trx_all cust_trx
	 	  --,ra_interface_lines_all int_lines
	 	  ,ra_cust_trx_types_all cust_trx_type, fnd_doc_sequence_assignments seqas
	 	  ,ra_batch_sources_all rbs  --mod 07/09/2009 defect 73657 --
		WHERE cust_trx.cust_trx_type_id (+) = cust_trx_type.cust_trx_type_id
		--AND cust_trx_type.name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO')  --mod 07/09/2009 defect 73657 --
		AND cust_trx_type.NAME=seqas.category_code
		AND seqas.method_code='A'
		AND seqas.set_of_books_id=1
		AND SYSDATE >= seqas.start_date
		AND (seqas.end_date IS NULL OR seqas.end_date>= SYSDATE)
--	 and 'RC-A-CRMO' = cust_trx_type.name
    --start mod 07/09/2009 defect 73657 --
    AND rbs.batch_source_id = cust_trx.batch_source_id
    AND rbs.NAME            = 'PMS_REFILL'
    AND rbs.org_id          = cust_trx.org_id
    --end mod 07/09/2009 defect 73657 --
	 GROUP BY --cust_trx_type.name,
	 seqas.doc_sequence_id
	 ) cust_trx,


	/* date transazioni  + numero transazione in interfaccia */
	(
	 SELECT  int_lines.trx_number,
	 				 int_lines.trx_date,
					 --int_lines.cust_trx_type_name,
					 seqas.doc_sequence_id
	 FROM ra_interface_lines_all int_lines,fnd_doc_sequence_assignments seqas
	 WHERE 1=1 --int_lines.cust_trx_type_name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO') --mod 07/09/2009 defect 73657 --
	 AND int_lines.batch_source_name = 'PMS_REFILL'
	 AND int_lines.cust_trx_type_name=seqas.category_code /* 10/04/2003 raggruppamento transazioni per sequenza */
	 AND seqas.method_code='A'
	 AND seqas.set_of_books_id=1
	 AND SYSDATE >= seqas.start_date
	 AND (seqas.end_date IS NULL OR seqas.end_date>= SYSDATE)
	 ) int_lines,

	/* date + recenti per ogni mese in interfaccia */
	(
	SELECT  seqas.doc_sequence_id
			--,cust_trx_type_name
		   ,TRUNC(trx_date,'MONTH') month_value
	       ,MAX(trx_date) date_value
	   FROM ra_interface_lines_all int_lines, fnd_doc_sequence_assignments seqas
	   WHERE trx_date IS NOT NULL
		--AND cust_trx_type_name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO') --mod 07/09/2009 defect 73657 --
		AND batch_source_name = 'PMS_REFILL'
		AND int_lines.cust_trx_type_name = seqas.category_code /* 10/04/2003 raggruppamento transazioni per sequenza */
		AND seqas.method_code='A'
		AND seqas.set_of_books_id=1
		AND SYSDATE >= seqas.start_date
		AND (seqas.end_date IS NULL OR seqas.end_date>= SYSDATE)
	   GROUP BY seqas.doc_sequence_id
	   --,cust_trx_type_name
	   , TRUNC(trx_date,'MONTH')
	  ) max_month
WHERE TRUNC(int_lines.trx_date,'MONTH') = max_month.month_value
AND int_lines.doc_sequence_id  = cust_trx.doc_sequence_id /* 10/04/2003 raggruppamento transazioni per sequenza */
AND mx_int_lines.doc_sequence_id  = cust_trx.doc_sequence_id
AND max_month.doc_sequence_id = cust_trx.doc_sequence_id
--AND int_lines.cust_trx_type_name = cust_trx.mx_trx_name
--AND mx_int_lines.cust_trx_type_name = cust_trx.mx_trx_name
--AND max_month.cust_trx_type_name = cust_trx.mx_trx_name
;

/* Global String Variable */
sql_statement_string VARCHAR2(1000);

BEGIN

FOR rec_trx IN c_trx_dates LOOP

		IF rec_trx.mx = rec_trx.mint AND rec_trx.mint < rec_trx.msys THEN

		   UPDATE ra_interface_lines_all SET trx_date = rec_trx.dsys WHERE trx_number = rec_trx.trx_number;

		dbms_output.put(' caso 1: Mx=Mint<Msys'); dbms_output.put_line(rec_trx.trx_number);

		ELSIF rec_trx.mx = rec_trx.msys AND rec_trx.mint = rec_trx.msys THEN


		   sql_statement_string := 'update ra_interface_lines_all set trx_date = ' ||
		   						   ' (select max(x) from (select :dx x from dual' || CHR(10) ||
								   	 			   		'union' || CHR(10)||
														'select :dsys x from dual'||CHR(10) ||
														'union' || CHR(10)||
--														'select :dint x from dual))'||CHR(10)|| --CR26180
                                                        'select :dint x from dual)),'||CHR(10)||--CR26180
                                                        'attribute5 = to_char(trx_date,''dd/mm/yyyy'')'||CHR(10)||      --CR26180
								   'where trx_number = :trx_num';

		   EXECUTE IMMEDIATE sql_statement_string USING rec_trx.dx, rec_trx.dsys, rec_trx.dint, rec_trx.trx_number;

		dbms_output.put(' caso 2: Mx=Msys=Mint'); dbms_output.put_line(rec_trx.trx_number);

		ELSIF rec_trx.mx = rec_trx.msys AND rec_trx.msys < rec_trx.mint THEN


		   sql_statement_string := 'update ra_interface_lines_all set trx_date = ' ||
		   						   '(select max(x) from (select :dx x from dual' || CHR(10) ||
								   	 			   		'union' || CHR(10)||
														'select :dint_month x from dual'||CHR(10)||
														'union' || CHR(10)||
--														'select :dsys x from dual))'||CHR(10) ||    --CR26180
                                                        'select :dsys x from dual)),'||CHR(10) ||   --CR26180
                                                        'attribute5 = to_char(trx_date,''dd/mm/yyyy'')'||CHR(10)||      --CR26180
								   'where trx_number = :trx_num';

		   EXECUTE IMMEDIATE sql_statement_string USING rec_trx.dx, rec_trx.dint_month, rec_trx.dsys, rec_trx.trx_number;

		   dbms_output.put(' caso 3: Mx=Msys<Mint '); dbms_output.put_line(rec_trx.trx_number);

		ELSIF rec_trx.msys < rec_trx.mx AND rec_trx.mx <= rec_trx.mint THEN


		   sql_statement_string := 'update ra_interface_lines_all set trx_date = ' ||
		   						   '(select max(x) from (select :dx x from dual' || CHR(10) ||
								   	 			   		'union' || CHR(10)||
--														'select :dint_month x from dual))'||CHR(10)||   --CR26180
                                                        'select :dint_month x from dual)),'||CHR(10)||  --CR26180
                                                        'attribute5 = to_char(trx_date,''dd/mm/yyyy'')'||CHR(10)||      --CR26180
								   'where trx_number = :trx_num';

		   EXECUTE IMMEDIATE sql_statement_string USING rec_trx.dx, rec_trx.dint_month, rec_trx.trx_number;

		dbms_output.put(' caso 4: Msys<Mx<=Mint '); dbms_output.put_line(rec_trx.trx_number);


		ELSIF rec_trx.mx < rec_trx.msys AND rec_trx.msys = rec_trx.mint THEN

		   sql_statement_string := 'update ra_interface_lines_all set trx_date = ' ||
		   						   '(select max(x) from (select :dint x from dual' || CHR(10) ||
								   	 			   		'union' || CHR(10)||
--														'select :dsys x from dual))'||CHR(10)||  --CR26180
                                                         'select :dsys x from dual)),'||CHR(10)||--CR26180
                                                         'attribute5 = to_char(trx_date,''dd/mm/yyyy'')'||CHR(10)||      --CR26180
								   'where trx_number = :trx_num';

		   EXECUTE IMMEDIATE sql_statement_string USING rec_trx.dint, rec_trx.dsys, rec_trx.trx_number;

		dbms_output.put(' caso 5: Mx<Msys=Mint '); dbms_output.put_line(rec_trx.trx_number);

		/* 10-apr-2003 casi 6,7 gestione transazioni non presenti a sistema */
		ELSIF rec_trx.mx  = rec_trx.mint THEN

		   sql_statement_string := 'update ra_interface_lines_all set trx_date = ' ||
		   						   '(select max(x) from (select :dx x from dual' || CHR(10) ||
								   	 			   		'union' || CHR(10)||
--														'select :dint x from dual))'||CHR(10)||  --CR26180
                                                         'select :dint x from dual)),'||CHR(10)||--CR26180
                                                         'attribute5 = to_char(trx_date,''dd/mm/yyyy'')'||CHR(10)||      --CR26180
								   'where trx_number = :trx_num';

		   EXECUTE IMMEDIATE sql_statement_string USING rec_trx.dx, rec_trx.dint, rec_trx.trx_number;

		dbms_output.put(' caso 6: Mx=Mint '); dbms_output.put_line(rec_trx.trx_number);

		ELSIF rec_trx.mx  < rec_trx.mint THEN

		   sql_statement_string := 'update ra_interface_lines_all set trx_date = ' ||
		   						   '(select max(x) from (select :dx x from dual' || CHR(10) ||
								   	 			   		'union' || CHR(10)||
--														'select :dint_month x from dual))'||CHR(10)||   --CR26180
                                                        'select :dint_month x from dual)),'||CHR(10)||  --CR26180
                                                        'attribute5 = to_char(trx_date,''dd/mm/yyyy'')'||CHR(10)||      --CR26180
								   'where trx_number = :trx_num';

		   EXECUTE IMMEDIATE sql_statement_string USING rec_trx.dx, rec_trx.dint_month, rec_trx.trx_number;

		dbms_output.put(' caso 7: Mx<Mint '); dbms_output.put_line(rec_trx.trx_number);

		END IF;

END LOOP;

		/* Le date TRX_DATE dovranno essere uguali alle GL_DATE per i records elaborati */
                --start mod 01/10/09 defect 74295 --
                /*
		UPDATE ra_interface_lines_all SET gl_date = trx_date WHERE trx_number IN
		(SELECT DISTINCT int_lines.trx_number
	 	  FROM ra_interface_lines_all int_lines,
	           ra_customer_trx_all cust_trx,
	           ra_cust_trx_types_all cust_types
	      WHERE --cust_types.name IN ('RC-A-CRMA','RC-A-ATM','RC-A-CRMR','RC-A-CRMO') --mod 07/09/2009 defect 73657 --
	      AND int_lines.batch_source_name = 'PMS_REFILL'
	      AND cust_trx.cust_trx_type_id = cust_types.cust_trx_type_id);
                */
                UPDATE ra_interface_lines_all
                SET    gl_date = trx_date
                WHERE  trx_number IN (SELECT DISTINCT int_lines.trx_number
                                      FROM   ra_interface_lines_all int_lines
                                      WHERE  int_lines.batch_source_name = 'PMS_REFILL');
                --end mod 01/10/09 defect 74295 --

		dbms_output.put_line('Transazioni aggiornate... ');

		FOR rec_trx_log IN c_trx_dates LOOP

			dbms_output.put_line('La data della fattura ' || rec_trx_log.trx_number ||
								' � stata aggiornata a: '|| rec_trx_log.DX);

		END LOOP;

END;
/
