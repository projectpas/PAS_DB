
/*************************************************************           
 ** File:   [usp_GetARInvoiceAgingReport]           
 ** Author:   Swetha  
 ** Description: Get Data for ARInvoiceAging Report 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** S NO   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha		Created
	2	        	  Swetha		Added Transaction & NO LOCK
	3	 01/02/2024	  AMIT GHEDIYA	added isperforma Flage for SO
     
--EXECUTE   [dbo].[usp_GetARInvoiceAgingReport] '','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetARInvoiceAgingReport] 
@customerid varchar(40)=null,
@mastercompanyid int,
@Level1 varchar(max) = null,
@Level2 varchar(max) = null,
@Level3 varchar(max) = null,
@Level4 varchar(max) = null

AS
  BEGIN
      SET nocount ON;
      SET TRANSACTION isolation level READ uncommitted

      BEGIN try
          BEGIN TRANSACTION

          IF Object_id(N'tempdb..#ManagmetnStrcture') IS NOT NULL
            BEGIN
                DROP TABLE #managmetnstrcture
            END

          CREATE TABLE #managmetnstrcture
            (
               id                    BIGINT NOT NULL IDENTITY,
               managementstructureid BIGINT NULL,
            )

           IF (ISNULL(@Level4, '0') != '0'
			AND ISNULL(@Level3, '0') != '0'
			AND ISNULL(@Level2, '0') != '0'
			AND ISNULL(@Level1, '0') != '0')
		  BEGIN
			INSERT INTO #managmetnstrcture (managementstructureid)
			  SELECT
				item
			  FROM dbo.[Splitstring](@Level4, ',')
		  END
		  ELSE
		  IF  (ISNULL(@Level3, '0') != '0'
			AND ISNULL(@Level2, '0') != '0'
			AND ISNULL(@Level1, '0') != '0')
		  BEGIN
			INSERT INTO #managmetnstrcture (managementstructureid)
			  SELECT
				item
			  FROM dbo.[Splitstring](@Level3, ',')

		  END
		  ELSE
		  IF (ISNULL(@Level2, '0') != '0'
			AND ISNULL(@Level1, '0') != '0')
		  BEGIN
			INSERT INTO #managmetnstrcture (managementstructureid)
			  SELECT
				item
			  FROM dbo.[Splitstring](@Level2, ',')
		  END
		  ELSE
		  IF ISNULL(@Level1, '0') != '0'
		  BEGIN
			INSERT INTO #managmetnstrcture (managementstructureid)
			  SELECT
				item
			  FROM dbo.[Splitstring](@Level1, ',')
		  END

				SELECT DISTINCT 
				c.customercode 'Customer Num',
				c.name 'Customer Name',
				(IsNull(Contact.FirstName,'')+' '+IsNull(Contact.LastName,'')) 'Contact',
				SOBI.invoicedate 'Invoice Date',
				SO.customerreference 'Customer Ref',
				SOBI.invoiceno 'Doc Num',
				SOBI.invoicestatus 'Doc Type',
				SO.salespersonname 'Salesperson',
				CT.name 'Terms',
				'?' 'Due Date',
				CUR.Code 'Currency',
				'?' 'FX Rate',
				SOBI.grandtotal 'Invoice Amt',
				SOBI.grandtotal 'Balance Amt',
                         CASE
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                                 AND level1.code + '-' + level1.NAME IS NOT NULL
                          THEN
                            level1.code + '-' + level1.NAME
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                          THEN
                            level2.code + '-' + level2.NAME
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                          THEN
                            level3.code + '-' + level3.NAME
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                          THEN
                            level4.code + '-' + level4.NAME
                            ELSE ''
                          END                                AS LEVEL1,
                          CASE
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                                 AND level1.code + '-' + level1.NAME IS NOT NULL
                          THEN
                            level2.code + '-' + level2.NAME
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                          THEN
                            level3.code + '-' + level3.NAME
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                          THEN
                            level4.code + '-' + level4.NAME
                            ELSE ''
                          END                                AS LEVEL2,
                          CASE
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                                 AND level1.code + '-' + level1.NAME IS NOT NULL
                          THEN
                            level3.code + '-' + level3.NAME
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                          THEN
                            level4.code + '-' + level4.NAME
                            ELSE ''
                          END                                AS LEVEL3,
                          CASE
                            WHEN level4.code + '-' + level4.NAME IS NOT NULL
                                 AND level3.code + '-' + level3.NAME IS NOT NULL
                                 AND level2.code + '-' + level2.NAME IS NOT NULL
                                 AND level1.code + '-' + level1.NAME IS NOT NULL
                          THEN
                            level4.code + '-' + level4.NAME
                            ELSE ''
                          END                                AS LEVEL4
			FROM  DBO.SalesOrder SO WITH(NOLOCK)
			INNER JOIN DBO.SalesOrderBillingInvoicing SOBI WITH(NOLOCK) ON SO.SalesOrderId=SOBI.SalesOrderId AND ISNULL(SOBI.IsProforma,0) = 0
			LEFT OUTER JOIN DBO.Customer C WITH(NOLOCK) ON SOBI.CustomerId=C.CustomerId
			LEFT OUTER JOIN DBO.Currency CUR WITH(NOLOCK) ON SOBI.CurrencyId=CUR.CurrencyId
			LEFT OUTER JOIN DBO.CustomerFinancial CF WITH(NOLOCK) ON C.CustomerId=CF.CustomerId
			LEFT OUTER JOIN DBO.CreditTerms CT WITH(NOLOCK) ON CF.CreditTermsId=CT.CreditTermsId
			LEFT OUTER JOIN DBO.CustomerContact CC WITH(NOLOCK) ON C.CustomerId=CC.CustomerId
			LEFT OUTER JOIN DBO.Contact WITH(NOLOCK) ON CC.ContactId=Contact.ContactId
			LEFT OUTER JOIN DBO.mastercompany MC WITH(NOLOCK) ON SOBI.MasterCompanyId=MC.MasterCompanyId
			INNER JOIN #ManagmetnStrcture MS WITH(NOLOCK) on MS.ManagementStructureId = SO.ManagementStructureId
			join  DBO.ManagementStructure level4 WITH(NOLOCK) on SO.ManagementStructureId = level4.ManagementStructureId
			LEFT join  DBO.ManagementStructure level3 WITH(NOLOCK) on level4.ParentId = level3.ManagementStructureId 
			LEFT join  DBO.ManagementStructure level2 WITH(NOLOCK) on level3.ParentId = level2.ManagementStructureId 
			LEFT join  DBO.ManagementStructure level1 WITH(NOLOCK) on level2.ParentId = level1.ManagementStructureId
            WHERE  (so.customerid IN (@customerid) OR @customerid = ' ' )
            AND SOBI.mastercompanyid = @mastercompanyid

          COMMIT TRANSACTION
      END try

      BEGIN catch
          ROLLBACK TRANSACTION

          IF Object_id(N'tempdb..#ManagmetnStrcture') IS NOT NULL
            BEGIN
                DROP TABLE #managmetnstrcture
            END

          DECLARE @ErrorLogID          INT,
                  @DatabaseName        VARCHAR(100) = Db_name()
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                  ,@AdhocComments VARCHAR(150) = '[usp_GetARInvoiceAgingReport]'
				  , @ProcedureParameters VARCHAR(3000)  =   '@Parameter1 = '''+ CAST(ISNULL(@customerid, '') as Varchar(100)) +
										  '@Parameter2 = '''+ CAST(ISNULL(@level1, '') as Varchar(100)) +	
										  '@Parameter3 = '''+ CAST(ISNULL(@level2, '') as Varchar(100)) +	
										  '@Parameter4 = '''+ CAST(ISNULL(@level3, '') as Varchar(100)) +	
										  '@Parameter5 = '''+ CAST(ISNULL(@level4, '') as Varchar(100)) +
										  '@Parameter6 = '''+ CAST(ISNULL(@mastercompanyid, '') as Varchar(100)) 									  	
				 , @ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
          EXEC Splogexception
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID output;

          RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID )

    RETURN ( 1 );
END catch
END