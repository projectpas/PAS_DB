/*************************************************************           
 ** File:   [USP_ValidateDistributionSetup]
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used for check Accounting Entry Bypass
 ** Purpose:         
 ** Date:   18/06/2026	[mm/dd/yyyy]      
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    18/06/2026		Moin Bloch				Created 	PN-16871

	EXEC [dbo].[USP_ValidateDistributionSetup] 1,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ValidateDistributionSetup]
@DistributionMasterId BIGINT=NULL,
@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @DistributionSetupId BIGINT=NULL
		DECLARE @IsAccountByPass BIT = 0;
		DECLARE @DistributionCode VARCHAR(200) = '';
		DECLARE @ExcludedAccountNumbers NVARCHAR(100) = '000,001,0000,0001,00000,00001,000000,000001,0000000,0000001'
		DECLARE @ExcludedAccountNames NVARCHAR(100) = 'NA,- NA, - NA';
		DECLARE @IsBypassAccounting BIT = 0;
		DECLARE @GlAccountId INT,@GlAccountName VARCHAR(200),@GlAccountNumber VARCHAR(200),@IsManualText BIT = 0,@ManualText VARCHAR(200)				
		DECLARE @IsValid             BIT = 1;
		DECLARE @ValidationMessage   VARCHAR(500) = '';

			
		SELECT @IsAccountByPass = ISNULL([IsAccountByPass],0) FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;	

		IF(@IsAccountByPass = 0)
		BEGIN 							
			IF EXISTS (SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId 
			       AND [IsActive] = 1 
				   AND [IsDeleted] = 0 
				   AND ISNULL([IsBypassAccounting], 0) = 0 
			       AND [DistributionMasterId] = @DistributionMasterId  
				   AND ISNULL([IsManualText],0) = 0
				   AND (ISNULL([GlAccountNumber], '') = ''
			        OR [GlAccountNumber] IN (SELECT VALUE FROM STRING_SPLIT(@ExcludedAccountNumbers, ','))						
					OR UPPER([GlAccountName]) IN (SELECT VALUE FROM STRING_SPLIT(@ExcludedAccountNames, ','))
					)
				)
				BEGIN
					SET @IsValid           = 0;
					SET @ValidationMessage = 'Distribution setup is missing or default GL account is assigned. '
										   + 'Please update the distribution setup before proceeding with this transaction.';						
				END				
		END	

		SELECT @IsValid AS [IsValid],@ValidationMessage AS [ValidationMessage]


	END TRY    
	BEGIN CATCH      
		
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_ValidateDistributionSetup' 
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@DistributionMasterId, '') AS VARCHAR(100))
			                                    + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 
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