/*************************************************************           
 ** File:   [GetAllVendorPaymentBankName]           
 ** Author:   unknown
 ** Description: Get All Vendor Payment Bank Name Based on LegalEntityId
 ** Purpose:         
 ** Date:   02/22/2022      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------              
	1    12/04/2023   Moin Bloch    Modified (SP Formated)
     
exec GetAllVendorPaymentBankName 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetAllVendorPaymentBankName]
@LegalEntityId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
			SELECT DISTINCT lebl.[LegalEntityBankingLockBoxId],
			       lebl.[BankName],
				   lebl.[BankAccountNumber],
				   lebl.[LegalEntityId],
				   lebl.[GLAccountId],
				   CONCAT(G.[AccountCode],' - ',G.[AccountName]) AS GLAccount,
				   lebl.[AccountTypeId],
				   lebl.[IsPrimay],
				   addr.[City] AS bankcity,
				   addr.[Line1] AS bankaddress 
			FROM [dbo].[LegalEntityBankingLockBox] lebl WITH (NOLOCK)
			INNER JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON lebl.GLAccountId = G.GLAccountId
			 LEFT JOIN [dbo].[Address] addr WITH(NOLOCK) ON addr.AddressId = lebl.AddressId
			WHERE lebl.[LegalEntityId] = @LegalEntityId AND (lebl.[AccountTypeId] = 2 OR lebl.[AccountTypeId] = 3)
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetAllVendorPaymentBankName' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END