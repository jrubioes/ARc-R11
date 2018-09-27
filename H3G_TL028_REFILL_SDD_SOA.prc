CREATE OR REPLACE PROCEDURE      H3G_TL028_REFILL_SDD_SOA
             (
               p_billing_account    IN  VARCHAR2
             , p_data_ricarica      IN  VARCHAR2
             , p_imp_ricarica       IN  VARCHAR2
             , p_transaction_id     IN  VARCHAR2
             , p_overall_id         IN  VARCHAR2
             , x_esito              OUT NUMBER
             , x_errbuf             OUT VARCHAR2
             )
  AS PRAGMA AUTONOMOUS_TRANSACTION;
--
-- ******************************************************************************************
-- * Client/Project:     H3G
-- * Description:        TL028 - Ricariche automatiche SDD da SOA
-- * Author:             L.Origoni
-- *
-- * Version:            1.0
-- * 
-- * Version    Date         Author           Change Reference/Description
-- * ========   ===========  ===============  ==============================================
-- * 1.0        03/01/2016   L.Origoni        Created (CR28979 drop 1 della CR28503
-- ******************************************************************************************
--
  l_refill_date          DATE;
  l_refill_amount        NUMBER;
  l_id_record            NUMBER;
  l_exist                NUMBER;
--
  errore_param           EXCEPTION;
  errore_insert          EXCEPTION;
--
BEGIN
--
--   
   IF p_billing_account IS NULL
   THEN
      x_errbuf := 'Billing account non valorizzato';
      RAISE errore_param;
   END IF;
   IF LENGTH(p_billing_account) > 50
   THEN
      x_errbuf := 'Billing account invalido';
      RAISE errore_param;
   END IF;
   --
   IF p_data_ricarica IS NULL
   THEN
      x_errbuf := 'Data ricarica non valorizzata';
      RAISE errore_param;
   END IF;
   BEGIN
      l_refill_date := TO_DATE(p_data_ricarica,'DD/MM/YYYY');
   EXCEPTION
      WHEN OTHERS THEN
         x_errbuf := 'Formato data ricarica invalido';
         RAISE errore_param;
   END;
   --
   IF p_imp_ricarica IS NULL
   THEN
      x_errbuf := 'Importo ricarica non valorizzato';
      RAISE errore_param;
   END IF;
   BEGIN
      l_refill_amount := TO_NUMBER(p_imp_ricarica);
   EXCEPTION
      WHEN OTHERS THEN
         x_errbuf := 'Formato importo ricarica invalido';
         RAISE errore_param;
   END;
   --
   IF p_transaction_id IS NULL
   THEN
      x_errbuf := 'Transaction ID logger non valorizzato';
      RAISE errore_param;
   END IF;
   IF LENGTH(p_transaction_id) > 30
   THEN
      x_errbuf := 'Transaction ID logger invalido';
      RAISE errore_param;
   END IF;
   --
   IF p_overall_id IS NULL
   THEN
      x_errbuf := 'Overall_id non valorizzato';
      RAISE errore_param;
   END IF;
   IF LENGTH(p_overall_id) > 100
   THEN
      x_errbuf := 'Overall_id invalido';
      RAISE errore_param;
   END IF;
   --
   BEGIN
      SELECT 1
        INTO l_exist
        FROM H3G_TL028_REFILL_SDD_INTERF
       WHERE transaction_id = p_transaction_id;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_exist := 0;
      WHEN OTHERS THEN
         x_errbuf := 'Errore ricerca transaction ID logger in tabella H3G_TL028_REFILL_SDD_INTERF: '||SQLERRM;
         RAISE errore_param;
   END;
   IF l_exist <> 0
   THEN
      x_errbuf := 'Transaction ID logger gia'' trasmesso';
      RAISE errore_param;                              
   END IF;
   --
    SELECT H3G_TL028_ID_REC_S.NEXTVAL
     INTO l_id_record
     FROM DUAL;
   --
   BEGIN
      INSERT INTO H3G_TL028_REFILL_SDD_INTERF
         (id_record,         
          transaction_id,
          overall_id,
          billing_account,
          refill_date,
          refill_amount,
          created_by,
          creation_date)
        VALUES
         (l_id_record,
          p_transaction_id,
          p_overall_id,
          p_billing_account,
          l_refill_date,
          l_refill_amount,
          'SOA',
          sysdate);
   EXCEPTION
      WHEN OTHERS THEN
         x_errbuf := 'Errore insert in tabella H3G_TL028_REFILL_SDD_INTERF: '||SQLERRM;
         RAISE errore_insert;
   END;
   --
   COMMIT;
   --
   x_esito := 0;
   --
   RETURN;
   --
EXCEPTION
   WHEN errore_param THEN
      x_esito := 1;
      RETURN;
   WHEN errore_insert THEN
      x_esito := 2;
      RETURN;
   WHEN OTHERS THEN
      x_esito  := 2;
      x_errbuf := 'Errore OTHER in procedure H3G_TL028_REFILL_SDD_SOA: '||SQLERRM;
      RETURN;
END H3G_TL028_REFILL_SDD_SOA;
/

