CREATE OR REPLACE PACKAGE BODY H3G_TL028_PKG
IS
--
--+============================================================================+
--| Con.Nexo (Italy) |
--| Milano, Italia |
--+============================================================================+
--| |
--| Description: Ricariche automatiche SDD da SOA |
--| |
--| |
--| Modification History: |
--| ----------------------- |
--| |
--| Author Date Version Remarks |
--| ------------------ ---------- ------- -------------------------------------|
--| L.Sinatra 25-02-2016 1.0 CR 28503 |
--+============================================================================+
--
-- Dichiarazioni Variabili Globali --
g_creation_date DATE := SYSDATE;
g_update_date DATE := SYSDATE;
g_created_by NUMBER := NVL( fnd_global.user_id, 1 );
g_updated_by NUMBER := NVL( fnd_global.user_id, 1 );
g_conc_request_id NUMBER := NVL (fnd_profile.VALUE ('CONC_REQUEST_ID'), 1);
--
PROCEDURE to_log (p_text VARCHAR2) IS
BEGIN
 fnd_file.put_line (fnd_file.LOG, p_text);
EXCEPTION
 WHEN OTHERS THEN
 NULL;
END to_log;
--
PROCEDURE to_out (p_text VARCHAR2) IS
BEGIN
 fnd_file.put_line (fnd_file.output, p_text);
EXCEPTION
 WHEN OTHERS THEN
 NULL;
END to_out;
--
PROCEDURE estraz_ric_sdd (
 errbuff OUT VARCHAR2,
 errcode OUT NUMBER)
IS
 l_rec_err h3g_tl028_error_details%ROWTYPE;
 l_ins_err NUMBER;
 --
 l_record_ins NUMBER;
 l_exist NUMBER;
 --
 err_ric EXCEPTION;
 --
 CURSOR c_ric_sdd
 IS
 SELECT A.*,
 rowid
 FROM h3g_tl028_refill_sdd_interf A
 WHERE NVL(status,'E') = 'E'
 ORDER BY id_record
 ;
 --
BEGIN
 --
 to_out('H3G TL028 Trasferimento Ricariche SDD');
 to_out('Data inizio esecuzione: '||TO_CHAR(g_creation_date,'DD/MM/YYYY HH24:MI:SS'));
 to_out('-----------------------------------------');
 to_log('H3G TL028 Trasferimento Ricariche SDD');
 to_log('Data inizio esecuzione: '||TO_CHAR(g_creation_date,'DD/MM/YYYY HH24:MI:SS'));
 to_log('-----------------------------------------');
 --
 DELETE h3g_tl028_error_details
 WHERE program_name = 'H3G_TL028_PKG'
 AND current_procedure = 'ESTRAZ_RIC_SDD';
 COMMIT;
 --
 l_record_ins := 0;
 --
 FOR r_ric_sdd IN c_ric_sdd
 LOOP
 BEGIN
 BEGIN
 SELECT 1
 INTO l_exist
 FROM h3g_tl028_refill_sdd
 WHERE transaction_id = r_ric_sdd.transaction_id;
 EXCEPTION
 WHEN OTHERS THEN
 l_exist := 0;
 END;
 IF l_exist <> 0
 THEN
 l_rec_err.error_code := 'E001';
 l_rec_err.oracle_sqlcode := NULL;
 l_rec_err.event_table := 'H3G_TL028_REFILL_SDD_INTERF';
 l_rec_err.event_key := 'TRANSACTION_ID = '||r_ric_sdd.transaction_id;
 l_rec_err.current_table := 'H3G_TL028_REFILL_SDD';
 l_rec_err.current_key := 'TRANSACTION_ID = '||r_ric_sdd.transaction_id;
 RAISE err_ric;
 ELSE
 BEGIN
 INSERT INTO h3g_tl028_refill_sdd
 (id_record,
 transaction_id,
 overall_id,
 billing_account,
 refill_date,
 refill_amount,
 creation_date,
 created_by,
 request_id
 )
 VALUES
 (r_ric_sdd.id_record,
 r_ric_sdd.transaction_id,
 r_ric_sdd.overall_id,
 r_ric_sdd.billing_account,
 r_ric_sdd.refill_date,
 r_ric_sdd.refill_amount,
 g_creation_date,
 g_created_by,
 g_conc_request_id
 );
 EXCEPTION
 WHEN OTHERS THEN
 l_rec_err.error_code := 'E002';
 l_rec_err.oracle_sqlcode := SQLCODE;
 l_rec_err.event_table := 'H3G_TL028_REFILL_SDD_INTERF';
 l_rec_err.event_key := 'TRANSACTION_ID = '||r_ric_sdd.transaction_id;
 l_rec_err.current_table := 'H3G_TL028_REFILL_SDD';
 l_rec_err.current_key := 'TRANSACTION_ID = '||r_ric_sdd.transaction_id;
 RAISE err_ric;
 END;
 l_record_ins := l_record_ins + 1;
 UPDATE h3g_tl028_refill_sdd_interf
 SET status = 'S'
 , last_updated_by = g_updated_by
 , last_update_date = g_update_date
 WHERE ROWID = r_ric_sdd.rowid;
 END IF;
 EXCEPTION
 WHEN err_ric THEN
 l_rec_err.program_name := 'APPS.H3G_TL028_PKG';
 l_rec_err.current_procedure := 'ESTRAZ_RIC_SDD';
 l_rec_err.start_date := sysdate;
 l_rec_err.creation_date := sysdate;
 l_rec_err.created_by := g_created_by;
 l_rec_err.request_id := g_conc_request_id;
 l_ins_err := 0;
 h3g_tl028_ins_errore(l_rec_err, l_ins_err);
 UPDATE h3g_tl028_refill_sdd_interf
 SET status = 'E'
 , last_updated_by = g_updated_by
 , last_update_date = g_update_date
 WHERE ROWID = r_ric_sdd.rowid;
 END;
 COMMIT;
 END LOOP;
 --
 to_log('Record inseriti : ' || l_record_ins);
 to_out('Record inseriti : ' || l_record_ins);
 --
 to_log('-----------------------------------------');
 to_log('Data fine esecuzione: '||TO_CHAR(sysdate,'DD/MM/YYYY HH24:MI:SS'));
 --
 to_out('-----------------------------------------');
 to_out('Data fine esecuzione: '||TO_CHAR(sysdate,'DD/MM/YYYY HH24:MI:SS'));
 --
EXCEPTION
 WHEN OTHERS THEN
 errbuff := 'Errore OTHER in H3G_TL028_PKG.estraz_ric_sdd: ' || SQLERRM;
 errcode := 2;
END estraz_ric_sdd;
--
PROCEDURE delete_ric_soa_sdd (
 errbuff OUT VARCHAR2,
 errcode OUT NUMBER,
 p_mesi_soa IN NUMBER,
 p_mesi_sdd IN NUMBER)
IS
 l_rec_err h3g_tl028_error_details%ROWTYPE;
 l_ins_err NUMBER;
 --
 l_exist NUMBER;
 l_record_del NUMBER;
 l_data_del_soa DATE;
 l_data_del_sdd DATE;
 --
 errore_grave EXCEPTION;
 errore_warn EXCEPTION;
 --
 CURSOR c_ric_soa
 IS
 SELECT id_record,
 rowid
 FROM h3g_tl028_refill_sdd_interf A
 WHERE TRUNC(creation_date) <= l_data_del_soa
 AND status = 'S'
 ORDER BY id_record
 ;
 --
 CURSOR c_ric_sdd
 IS
 SELECT A.*,
 rowid
 FROM h3g_tl028_refill_sdd A
 WHERE TRUNC(creation_date) <= l_data_del_sdd
 AND (ar_status = 'S'
 OR mtfs_result = 'OK'
 OR ko_ar_status = 'S'
 OR gl_status = 'S')
 ORDER BY id_record
 ;
 --
BEGIN
 --
 to_out('H3G TL028 Cancellazione Ricariche SDD');
   to_out('Data inizio esecuzione: '||TO_CHAR(g_creation_date,'DD/MM/YYYY HH24:MI:SS'));
   to_out('-----------------------------------------');
   to_log('H3G TL028 Cancellazione Ricariche SDD');
   to_log('Data inizio esecuzione: '||TO_CHAR(g_creation_date,'DD/MM/YYYY HH24:MI:SS'));
   to_log('-----------------------------------------');
   --
   DELETE h3g_tl028_error_details
    WHERE program_name      = 'H3G_TL028_PKG'
      AND current_procedure = 'DELETE_RIC_SOA_SDD';
   COMMIT;
   --
   IF p_mesi_soa IS NULL
   THEN
      to_log ('Il parametro numero mesi SOA e'' obbligatorio !');
      RAISE errore_warn;
   END IF;
   --
   IF p_mesi_sdd IS NULL
   THEN
      to_log ('Il parametro numero mesi SDD e'' obbligatorio !');
      RAISE errore_warn;
   END IF;
   --
   to_log ('Numero mesi SOA: '||p_mesi_soa);
   to_log ('Numero mesi SDD: '||p_mesi_sdd);
   to_log ('-------------------------------------------------');
   --
   SELECT TRUNC(ADD_MONTHS(sysdate,p_mesi_soa*(-1)))
     INTO l_data_del_soa
     FROM DUAL;
   --
   SELECT TRUNC(ADD_MONTHS(sysdate,p_mesi_sdd*(-1)))
     INTO l_data_del_sdd
     FROM DUAL;
   --
   l_record_del := 0;
   --
   FOR r_ric_soa
    IN c_ric_soa
   LOOP
      BEGIN
         SELECT 1
           INTO l_exist
           FROM h3g_tl028_refill_sdd
          WHERE id_record = r_ric_soa.id_record;
      EXCEPTION
         WHEN OTHERS THEN
            l_exist := 0;
      END;
      IF l_exist <> 0
      THEN
         DELETE h3g_tl028_refill_sdd_interf
          WHERE rowid = r_ric_soa.rowid;
         l_record_del := l_record_del + 1;
      ELSE
         l_rec_err.error_code        := 'E004';
         l_rec_err.oracle_sqlcode    := NULL;
         l_rec_err.event_table       := 'H3G_TL028_REFILL_SDD_INTERF';
         l_rec_err.event_key         := 'ID_RECORD = '||r_ric_soa.id_record;
         l_rec_err.current_table     := 'H3G_TL028_REFILL_SDD';
         l_rec_err.current_key       := 'ID_RECORD = '||r_ric_soa.id_record;
         l_rec_err.program_name      := 'H3G_TL028_PKG';
         l_rec_err.current_procedure := 'DELETE_RIC_SOA_SDD';
         l_rec_err.start_date        := sysdate;
         l_rec_err.creation_date     := sysdate;
         l_rec_err.created_by        := g_created_by;
         l_rec_err.request_id        := g_conc_request_id;
         l_ins_err                   := 0;
         h3g_tl028_ins_errore(l_rec_err, l_ins_err);
      END IF;
   END LOOP;
   --
   COMMIT;
   --
   to_log('Record cancellati SOA: ' || l_record_del);
   to_out('Record cancellati SOA: ' || l_record_del);
   --
   l_record_del := 0;
   --
   FOR r_ric_sdd
    IN c_ric_sdd
   LOOP
      BEGIN
         INSERT INTO h3g_tl028_refill_sdd_bck
            (id_record,
             transaction_id,
             overall_id,
             billing_account,
             refill_date,
             refill_amount,
             cust_account_id,
             bill_to_site_use_id,
             mdp_type,
             receipt_method_id,
             bank_account_id,
             term_id,
             ar_status,
             trx_header_id,
             trx_date,
             due_date,
             customer_trx_id,
             program_name,
             card_type,
             cdc_expire_date,
             cdc_num,
             mtfs_status,
             mtfs_id,
             mtfs_file,
             mtfs_due_date,
             mtfs_result,
             ko_ar_status,
             ko_customer_trx_id,
             gl_reference,
             gl_status,
             je_header_id,
             je_line_num,
             period_name,
             creation_date,
             created_by,
             last_update_date,
             last_updated_by,
             etl_update_date,
             request_id,
             flow_type,
             num_tranche,
             creation_date_bck,
             created_by_bck,
             request_id_bck
            )
          VALUES
            (r_ric_sdd.id_record,
             r_ric_sdd.transaction_id,
             r_ric_sdd.overall_id,
             r_ric_sdd.billing_account,
             r_ric_sdd.refill_date,
             r_ric_sdd.refill_amount,
             r_ric_sdd.cust_account_id,
             r_ric_sdd.bill_to_site_use_id,
             r_ric_sdd.mdp_type,
             r_ric_sdd.receipt_method_id,
             r_ric_sdd.bank_account_id,
             r_ric_sdd.term_id,
             r_ric_sdd.ar_status,
             r_ric_sdd.trx_header_id,
             r_ric_sdd.trx_date,
             r_ric_sdd.due_date,
             r_ric_sdd.customer_trx_id,
             r_ric_sdd.program_name,
             r_ric_sdd.card_type,
             r_ric_sdd.cdc_expire_date,
             r_ric_sdd.cdc_num,
             r_ric_sdd.mtfs_status,
             r_ric_sdd.mtfs_id,
             r_ric_sdd.mtfs_file,
             r_ric_sdd.mtfs_due_date,
             r_ric_sdd.mtfs_result,
             r_ric_sdd.ko_ar_status,
             r_ric_sdd.ko_customer_trx_id,
             r_ric_sdd.gl_reference,
             r_ric_sdd.gl_status,
             r_ric_sdd.je_header_id,
             r_ric_sdd.je_line_num,
             r_ric_sdd.period_name,
             r_ric_sdd.creation_date,
             r_ric_sdd.created_by,
             r_ric_sdd.last_update_date,
             r_ric_sdd.last_updated_by,
             r_ric_sdd.etl_update_date,
             r_ric_sdd.request_id,
             r_ric_sdd.flow_type,
             r_ric_sdd.num_tranche,
             g_creation_date,
             g_created_by,
             g_conc_request_id
            );
      EXCEPTION
         WHEN OTHERS THEN
            l_rec_err.error_code        := 'E003';
            l_rec_err.oracle_sqlcode    := SQLCODE;
            l_rec_err.event_table       := 'H3G_TL028_REFILL_SDD';
            l_rec_err.event_key         := 'ID_RECORD = '||r_ric_sdd.id_record;
            l_rec_err.current_table     := 'H3G_TL028_REFILL_SDD_BCK';
            l_rec_err.current_key       := 'ID_RECORD = '||r_ric_sdd.id_record;
            l_rec_err.program_name      := 'H3G_TL028_PKG';
            l_rec_err.current_procedure := 'DELETE_RIC_SOA_SDD';
            l_rec_err.start_date        := sysdate;
            l_rec_err.creation_date     := sysdate;
            l_rec_err.created_by        := g_created_by;
            l_rec_err.request_id        := g_conc_request_id;
            l_ins_err                   := 0;
            h3g_tl028_ins_errore(l_rec_err, l_ins_err);
      END;
      DELETE h3g_tl028_refill_sdd
       WHERE rowid = r_ric_sdd.rowid;
      l_record_del := l_record_del + 1;
   END LOOP;
   --
   COMMIT;
   --
   to_log('Record cancellati SDD: ' || l_record_del);
   to_out('Record cancellati SDD: ' || l_record_del);
   --
   to_log('-----------------------------------------');
   to_log('Data fine esecuzione: '||TO_CHAR(sysdate,'DD/MM/YYYY HH24:MI:SS'));
   --
   to_out('-----------------------------------------');
   to_out('Data fine esecuzione: '||TO_CHAR(sysdate,'DD/MM/YYYY HH24:MI:SS'));
   --
   --
EXCEPTION
   WHEN errore_warn THEN
      errcode := 1;
   WHEN OTHERS THEN
      errbuff := 'Errore OTHER in H3G_TL028_PKG.delete_ric_soa_sdd: ' || SQLERRM;
      errcode := 2;
END delete_ric_soa_sdd;
--
PROCEDURE invio_ermail
        (
         p_tipo_mail IN VARCHAR2, 
         p_filepath  IN VARCHAR2,
         x_cod_err   OUT NUMBER,
         x_desc_err  OUT VARCHAR2
        ) IS
--
   l_mail_id        NUMBER;
   l_lista_to       VARCHAR2(1000);
   l_lista_cc       VARCHAR2(1000);
   l_insok          VARCHAR2(1);
   l_descr_pgm      VARCHAR2(80);
   l_text_header    VARCHAR2(150);
   l_text_footer    VARCHAR2(150);
   l_errbuf         VARCHAR2(200);
   l_errcod         NUMBER;
--
   quit        EXCEPTION;
--
BEGIN
   --
   x_cod_err  := 0;
   x_desc_err := NULL;
   --
   BEGIN
      SELECT lista_mail_to,
             lista_mail_cc
        INTO l_lista_to,
             l_lista_cc
        FROM h3g.h3g_rubrica_mail
       WHERE tipo_mail = p_tipo_mail;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         x_desc_err := 'Attenzione non esistono i riferimenti del tipo mail ' || p_tipo_mail;
         x_cod_err  := -1;
         RAISE quit;
      WHEN OTHERS THEN
         x_desc_err := 'Recupero indirizzi mail - ' || SQLERRM;
         x_cod_err  := -1;
         RAISE quit;
   END;
   --
   IF l_lista_to IS NULL AND
      l_lista_cc IS NULL
   THEN
      x_desc_err := 'Indirizzi mail non valorizzati per tipo mail ' || p_tipo_mail;
      x_cod_err  := -1;
      RAISE quit;
   END IF;
   --
   BEGIN
      SELECT meaning,
             attribute1,
             attribute2
        INTO l_descr_pgm,
             l_text_header,
             l_text_footer
        FROM fnd_lookup_values_vl
       WHERE lookup_type  = 'H3G_TL028_PROGRAMS'
         AND lookup_code  = p_tipo_mail;
   EXCEPTION
      WHEN OTHERS THEN
         l_descr_pgm := 'UNIDENTIFIED PROGRAM';
   END;
   --
   h3g_gestione_mail.h3g_scrivi_outbox
                     (l_errbuf
                    , l_errcod
                    , l_mail_id
                    , p_tipo_mail
                    , NULL
                    , NULL
                    , l_lista_to
                    , l_lista_cc
                    , l_descr_pgm||': Report errori'
                    , l_text_header
                    , NULL
                    , p_filepath
                    , l_text_footer
                    , NULL
                    , 'N'
                    , NULL
                    , l_insok
                     );
   h3g_gestione_mail.h3g_send_mail
                     (l_errbuf,
                      l_errcod,
                      l_mail_id,
                      p_tipo_mail, 
                      NULL, 
                      NULL, 
                      'N', 
                      NULL);
   --
   COMMIT;
   --
EXCEPTION
   WHEN quit THEN
      NULL;
   WHEN OTHERS THEN
      x_desc_err := SQLERRM;
      x_cod_err  := -1;
END invio_ermail;
--
PROCEDURE report_errori
(  x_errbuff     OUT  VARCHAR2
 , x_errcode     OUT  NUMBER
 , p_nome_pgm    IN   VARCHAR2
 , p_ente        IN   VARCHAR2
)
IS
   errore                 EXCEPTION;
   reportfile             UTL_FILE.file_type;
   l_errore               VARCHAR2 (255);
   l_report               VARCHAR2 (255);
   l_path                 VARCHAR2 (240):= fnd_profile.VALUE ('H3G_TOP');
   l_file                 VARCHAR2 (255);
   l_timestamp            VARCHAR2 (255);
   l_conta                NUMBER;
--
   l_mail_id              NUMBER;
   l_errbuf               VARCHAR2(200);
   l_errcod               NUMBER;
   l_error_found          VARCHAR2(2);
   l_ente                 VARCHAR2(100);
   l_prog_name            VARCHAR2(30);
--
   ln_req                 NUMBER;
   lb_get_request_status  BOOLEAN;
   lv_phase               VARCHAR2 (2000)    := '';
   lv_status              VARCHAR2 (2000)    := '';
   lv_dev_phase           VARCHAR2 (2000)    := '';
   lv_dev_status          VARCHAR2 (2000)    := '';
   lv_message             VARCHAR2 (2000)    := '';
   v_filename_zip         VARCHAR2 (70);
--
   CURSOR cur_err IS
      SELECT NVL(flv.attribute1, ' ') ente,
             hed.program_name,
             hed.current_procedure,
             hed.start_date,
             hed.current_table,
             hed.current_key,
             hed.error_code,
             hed.error_descr,
             hed.oracle_sqlcode,
             hed.event_table,
             hed.event_key,
             hed.request_id
        FROM h3g_tl028_error_details hed,
             fnd_lookup_values_vl flv
       WHERE flv.lookup_type   = 'H3G_TL028_GESTIONE_ERRORI'
         AND hed.error_code    = flv.lookup_code
         AND hed.program_name  = NVL(p_nome_pgm,hed.program_name)
       ORDER BY 1;
BEGIN
   to_log ('Inizio procedura...');
   --
   l_path      := l_path || '/out';
   l_timestamp := TO_CHAR (SYSDATE, 'yyyymmddhh24miss');
   l_conta     := 0;
   --
   l_ente        := NULL;
   l_prog_name   := NULL;
   l_error_found := 'NO';
   --
   FOR rec_err
    IN cur_err
   LOOP
      l_error_found := 'SI';
      --
      IF l_ente IS NULL
      THEN
         l_ente      := rec_err.ente;
         l_prog_name := SUBSTR(rec_err.program_name,5,instr(rec_err.program_name,'_',6)-instr(rec_err.program_name,'_',1)-1);
         l_report    := l_prog_name || '_' || l_ente || '_' || l_timestamp || '.txt';
         --
         BEGIN
            reportfile := UTL_FILE.fopen (l_path, l_report, 'w');
         EXCEPTION
            WHEN OTHERS THEN
               l_errore := 'Apertura file ' || l_path || '/' || l_report || ' - ' || SQLERRM;
               RAISE errore;
         END;
      ELSE
         IF (l_ente != rec_err.ente)
         THEN
            UTL_FILE.fclose(reportfile);
            v_filename_zip := REPLACE (l_report, '.txt', '');
            ln_req :=
               fnd_request.submit_request
                          (application    => 'H3G'
                         , PROGRAM        => 'H3GUTLZIP'
                         , description    => 'Utility per compressione files'
                         , start_time     => ''
                         , sub_request    => FALSE
                         , argument1      => l_path
                         , argument2      => l_report
                         , argument3      => l_path
                         , argument4      => REPLACE(v_filename_zip,' ','')
                         , argument5      => 'Y'
                          );
            COMMIT;
            lb_get_request_status :=
               fnd_concurrent.wait_for_request
                          (request_id    => ln_req
                         , INTERVAL      => 5
                         , max_wait      => 0
                         , message       => lv_message
                         , phase         => lv_phase
                         , status        => lv_status
                         , dev_phase     => lv_dev_phase
                         , dev_status    => lv_dev_status
                          );
            IF (lv_status LIKE 'Normal%')
            THEN
               invio_ermail (l_prog_name||'_'||l_ente, l_path || '/' || v_filename_zip||'.gz', l_errcod, l_errbuf);
               IF (l_errcod = -1) THEN
                  l_errore := 'Errore invio mail degli errori - ' || l_errbuf;
                  RAISE errore;
               END IF;
            ELSE
               l_errore := 'Errore generazione file zip - ' || l_errbuf;
               RAISE errore;
            END IF;
            --
            l_ente      := rec_err.ente;
            l_prog_name := SUBSTR(rec_err.program_name,5,instr(rec_err.program_name,'_',6)-instr(rec_err.program_name,'_',1)-1);
            l_report    := l_prog_name || '_' || l_ente || '_' || l_timestamp || '.txt';
            --
            BEGIN
               reportfile := UTL_FILE.fopen (l_path, l_report, 'w');
            EXCEPTION
               WHEN OTHERS THEN
                  l_errore := 'Apertura file ' || l_path || '/' || l_report || ' - ' || SQLERRM;
                  RAISE errore;
            END;
            --
            l_conta     := 0;
         END IF;
      END IF;
      --
      IF (l_conta = 0)
      THEN
         BEGIN
            UTL_FILE.put_line
               (reportfile,
                    'Ente di Competenza'
                 || CHR (9)
                 || 'Nome Programma'
                 || CHR (9)
                 || 'Procedura'
                 || CHR (9)
                 || 'Data'
                 || CHR (9)
                 || 'Nome Tabella Corrente'
                 || CHR (9)
                 || 'Chiave Tabella Corrente'
                 || CHR (9)
                 || 'Codice Errore'
                 || CHR (9)
                 || 'Descrizione Errore'
                 || CHR (9)
                 || 'Errore Oracle'
                 || CHR (9)
                 || 'Nome tabella Elab.'
                 || CHR (9)
                 || 'Chiave Tabella Elab.'
                 || CHR (9)
                 || 'ID Richiesta'
               );
         EXCEPTION
            WHEN OTHERS THEN
               l_errore := 'Scrittura file (testata) ' || l_path || '/' || l_report || ' - ' || SQLERRM;
               RAISE errore;
         END;
         l_conta := 1;
      END IF;
      --
      BEGIN
         UTL_FILE.put_line
            (reportfile,
                 rec_err.ente
              || CHR (9)
              || rec_err.program_name
              || CHR (9)
              || rec_err.current_procedure
              || CHR (9)
              || rec_err.start_date
              || CHR (9)
              || rec_err.current_table
              || CHR (9)
              || rec_err.current_key
              || CHR (9)
              || rec_err.error_code
              || CHR (9)
              || rec_err.error_descr
              || CHR (9)
              || rec_err.oracle_sqlcode
              || CHR (9)
              || rec_err.event_table
              || CHR (9)
              || rec_err.event_key
              || CHR (9)
              || rec_err.request_id
             );
      EXCEPTION
         WHEN OTHERS THEN
            l_errore := 'Scrittura file (dettaglio) ' || l_path || '/' || l_report || ' - ' || SQLERRM;
            RAISE errore;
      END;
   END LOOP;
   --
   IF l_error_found = 'SI'
   THEN
      UTL_FILE.fclose (reportfile);
      v_filename_zip := REPLACE (l_report, '.txt', '');
      ln_req :=
        fnd_request.submit_request (application    => 'H3G'
                                  , PROGRAM        => 'H3GUTLZIP'
                                  , description    => 'Utility per compressione files'
                                  , start_time     => ''
                                  , sub_request    => FALSE
                                  , argument1      => l_path
                                  , argument2      => l_report
                                  , argument3      => l_path
                                  , argument4      => v_filename_zip
                                  , argument5      => 'Y'
                                   );
      COMMIT;
      lb_get_request_status :=
        fnd_concurrent.wait_for_request (request_id    => ln_req
                                       , INTERVAL      => 5
                                       , max_wait      => 0
                                       , MESSAGE       => lv_message
                                       , phase         => lv_phase
                                       , status        => lv_status
                                       , dev_phase     => lv_dev_phase
                                       , dev_status    => lv_dev_status
                                        );
      COMMIT;
      IF (lv_status LIKE 'Normal%')
      THEN
         invio_ermail(l_prog_name||'_'||l_ente, l_path || '/' || v_filename_zip||'.gz', l_errcod, l_errbuf);
         IF (l_errcod = -1)
         THEN
            l_errore := 'Errore invio mail degli errori - ' || l_errbuf;
            RAISE errore;
         END IF;
      ELSE
         l_errore := 'Errore generazione file zip - ' || l_errbuf;
         RAISE errore;
      END IF;
   END IF;
   --
EXCEPTION
   WHEN errore THEN
      x_errcode := 2;
      x_errbuff := 'Errore. Verifica log. --> ' || l_errore;
   WHEN OTHERS THEN
      x_errcode := 2;
      x_errbuff := 'Errore OTHER in H3G_TL028_PKG.report_errori: '||SQLERRM;
END report_errori;
--
END H3G_TL028_PKG;
/

