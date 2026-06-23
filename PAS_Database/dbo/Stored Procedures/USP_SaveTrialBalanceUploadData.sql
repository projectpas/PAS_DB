/*************************************************************           
 ** File:		 [USP_SaveTrialBalanceUploadData]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Save Trial Balance Upload Data List.
 ** Purpose:         
 ** Date:   23-JUNE-2026 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    23-JUNE-2026		Divyesh Kathiriya	Created
    
 -- EXEC [USP_SaveTrialBalanceUploadData] @Status=N'Uploaded',@TotalRecords=2,@ErrorDetails=N'',@FilePath=N'UAT_FILES/1/UploadFiles/TrialBalanceUpload/Import_TrialBalance_Blank_Template.xlsm',
                                          @CreatedBy=N'dane park',@UpdatedBy=N'dane park',@CreatedDate='2026-06-01 13:42:49.403',@UpdatedDate='2026-06-01 13:42:49.403',@MasterCompanyId=1,@IsActive=1,@IsDeleted=0
**************************************************************/
Create   PROCEDURE [DBO].[USP_SaveTrialBalanceUploadData]
    @Status           VARCHAR(50) = NULL,
    @TotalRecords     BIGINT = NULL,
    @ErrorDetails     NVARCHAR(MAX) = NULL,
    @FilePath         NVARCHAR(MAX) = NULL,
    @CreatedBy        VARCHAR(256),
    @UpdatedBy        VARCHAR(256),
    @CreatedDate      DATETIME2(7) = NULL,
    @UpdatedDate      DATETIME2(7) = NULL,
    @MasterCompanyId  INT,
    @IsActive         BIT = 1,
    @IsDeleted        BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO [dbo].[TrialBalanceUpload]
        (
            [Status],
            [TotalRecords],
            [ErrorDetails],
            [FilePath],
            [CreatedBy],
            [UpdatedBy],
            [CreatedDate],
            [UpdatedDate],
            [MasterCompanyId],
            [IsActive],
            [IsDeleted]
        )
        VALUES
        (
            @Status,
            @TotalRecords,
            @ErrorDetails,
            @FilePath,
            @CreatedBy,
            @UpdatedBy,
            ISNULL(@CreatedDate, GETUTCDATE()),
            ISNULL(@UpdatedDate, GETUTCDATE()),
            @MasterCompanyId,
            @IsActive,
            @IsDeleted
        );

        DECLARE @TrialBalanceUploadId BIGINT = SCOPE_IDENTITY();

        SELECT
            [TrialBalanceUploadId],
            [Status],
            [TotalRecords],
            [ErrorDetails],
            [FilePath],
            [CreatedBy],
            [UpdatedBy],
            [CreatedDate],
            [UpdatedDate],
            [MasterCompanyId],
            [IsActive],
            [IsDeleted]
        FROM [dbo].[TrialBalanceUpload] WITH (NOLOCK)
        WHERE [TrialBalanceUploadId] = @TrialBalanceUploadId;	
	
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveTrialBalanceUploadData'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END