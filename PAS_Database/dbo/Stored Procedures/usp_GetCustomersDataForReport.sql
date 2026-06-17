/*************************************************************           
 ** File:   [usp_GetCustomersDataForReport]           
 ** Author:   Sumit Kumar
 ** Description: This stored procedure is used to Get Customers Data For Report
 ** Purpose:    To retrieve customer data for reporting purposes
 ** Date:   02-06-2026

 ** RETURN VALUE:

 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    02-06-2026       Sumit Kumar       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_GetCustomersDataForReport]
    @MasterCompanyId INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        SELECT 
              [Name]
            , [CustomerCode]
            , [DoingBuinessAsName]
            , [IsParent]
            , [CustomerPhone]
            , [CustomerPhoneExt]
            , [Email]
            , [AddressId]
            , [IsAddressForBilling]
            , [IsAddressForShipping]
            , [IsCustomerAlsoVendor]
            , [ContractReference]
            , [IsPBHCustomer]
            , [PBHCustomerMemo]
            , [CustomerURL]
            , [RestrictPMA]
            , [RestrictDER]
            , [CreatedBy]
            , [UpdatedBy]
            , [CreatedDate]
            , [UpdatedDate]
            , [IsActive]
            , [IsDeleted]
            , [IsCRMCustomer]
            , [IsTradeRestricted]
            , [TradeRestrictedMemo]
            , [IsTrackScoreCard]
            , [CommunicationPreference]
            , [Ismiscellaneous]
            , [IsStageChange]
            , [IsCommunicationPreference]
            , [IsCustomerShipping]
            , [IsUpdated]
            , [LastSyncDate]
            , [Memo]
            , [SyncToken]
        FROM [dbo].[Customer] WITH (NOLOCK)
        WHERE 
            MasterCompanyId = @MasterCompanyId
            AND IsActive = @IsActive
            AND ISNULL(IsDeleted, 0) = 0;

    END TRY    

    BEGIN CATCH      

        IF @@TRANCOUNT > 0
            -- no transaction here, but kept for consistency with your pattern
            PRINT 'Error occurred';

        DECLARE 
              @ErrorLogID INT,
              @DatabaseName VARCHAR(100) = DB_NAME()

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments VARCHAR(150) = 'usp_GetCustomersDataForReport'
            , @ProcedureParameters VARCHAR(3000) = 
                    '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(50)), '') +
                    ', @IsActive = ' + ISNULL(CAST(@IsActive AS VARCHAR(10)), '')
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

        EXEC spLogException 
              @DatabaseName = @DatabaseName
            , @AdhocComments = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName = @ApplicationName
            , @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );

        RETURN (1);

    END CATCH
END