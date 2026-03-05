/*************************************************************           
** File:  [USP_AddCustomerContact] 
** Author:    Amit Ghediya 
** Description: Add Customer Contact
** Purpose:  
** Date:   07-01-2026  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     07-01-2026   Amit Ghediya      Created  

exec [USP_AddCustomerContact] 4307,ax,'','','',1,1,'VICTOR ADMAS','VICTOR ADMAS'
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddCustomerContact]
    @CustomerId BIGINT,
    @CustomerName NVARCHAR(100),
    @CustomerEmail NVARCHAR(100),
    @CustomerPhone NVARCHAR(50),
    @CustomerPhoneExt NVARCHAR(50),
    @MasterCompanyId BIGINT,
    @IsActive BIT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100),
	@CustomerContactId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ContactId BIGINT = NULL;
        --DECLARE @CustomerContactId BIGINT = NULL;
		DECLARE @CustomerModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Customer');
        
		INSERT INTO Contact (
                FirstName, LastName, Email, Tag, WorkPhone, WorkPhoneExtn,
                MasterCompanyId, IsActive, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy
            )
            VALUES (
                @CustomerName, 'NA', @CustomerEmail, 'NA', @CustomerPhone, @CustomerPhoneExt,
                @MasterCompanyId, 1, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy
            );

            SET @ContactId = SCOPE_IDENTITY();

            INSERT INTO CustomerContact (
                ContactId, CustomerId, IsDefaultContact, MasterCompanyId, IsActive, IsDeleted,
                CreatedDate, UpdatedDate, CreatedBy, UpdatedBy
            )
            VALUES (
                @ContactId, @CustomerId, 0, @MasterCompanyId, @IsActive, 0,
                GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy
            );

            SET @CustomerContactId = SCOPE_IDENTITY();

            EXEC dbo.USP_ContactsHistory @CustomerId, @CustomerModuleId, @CustomerContactId, @UpdatedBy;
    END TRY
    BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddCustomerContact' 
            , @ProcedureParameters VARCHAR(3000) = '@CustomerId = ''' + CAST(ISNULL(@CustomerId, '') as varchar(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END