/*************************************************************             
 ** File:   [GetDistributionSetupData]             
 ** Author:   Subhash Saliya  
 ** Description: Get Data for GetDistributionSetupData  
 ** Purpose:           
 ** Date:   09/08/2022   
 ** PARAMETERS:             
 @POId varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    09/08/2022   Subhash Saliya	Created  
    2    11/07/2023   Satish Gohil		CRDRType Column added
	3    17/09/2024   AMIT GHEDIYA		added AutoPost.
	4    27/10/2025   AMIT GHEDIYA		update for get glaccount from LE.
	5	 26/01/2026   AMIT GHEDIYA		update for get glaccount details.
       
 EXECUTE [GetDistributionSetupData] 1,9 ,1
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetDistributionSetupData](  
	@masterCompanyId BIGINT = NULL,  
	@JournalTypeID BIGINT = NULL,
	@legalEntityId BIGINT = NULL
)
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON
	BEGIN TRY 
	BEGIN 
		
		DECLARE @JournalTypeCode VARCHAR(50) = NULL, 
				@CheckCode VARCHAR(50) = 'CKS',
				@CreditCardCode VARCHAR(50) = 'CCP',
				@WireCode VARCHAR(50) = 'WRT',
				@ACHCode VARCHAR(50) = 'ACHT',
				@DistributionSetupCode VARCHAR(50) = NULL,
				@GLAccountId BIGINT = 0,
				@DefaultGLAccountId BIGINT = 0,
				@GlAccountName VARCHAR(200) = NULL,
				@GlAccountCode VARCHAR(50) = NULL;

		SELECT @JournalTypeCode = [JournalTypeCode] FROM [DBO].[JournalType] WITH(NOLOCK) WHERE [ID] = @JournalTypeID;

		--For Check (Vendor Payment)
		IF(@JournalTypeCode = @CheckCode)
		BEGIN
			-- DECLARE @GLAccountId BIGINT = 0, @GlAccountName VARCHAR(200) = NULL;

			 SELECT @GLAccountId = [GLAccountId] FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityId] = @legalEntityId AND [IsPrimary] = 1;
			 
			 IF(ISNULL(@GLAccountId,0) > 0)
			 BEGIN
				  SELECT @GlAccountName = [AccountName], @GlAccountCode = [AccountCode] FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GLAccountId;
			 END

			 SELECT @DistributionSetupCode = [DistributionSetupCode], @DefaultGLAccountId = [GlAccountId] FROM [DBO].[DistributionSetup] WITH(NOLOCK) 
			 WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'CheckPayment')
			 AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'CKS')
			 AND MasterCompanyId = @masterCompanyId
			 AND DistributionSetupCode = 'CKSBANKACCOUNT';

			 --Update GL Account
			 IF(ISNULL(@GLAccountId,0) > 0 AND ISNULL(@DefaultGLAccountId,0) = 0)
			 BEGIN
				 UPDATE [DBO].[DistributionSetup] SET [GlAccountId] = @GLAccountId, [GlAccountName] = @GlAccountName, [GlAccountNumber] = @GlAccountCode
					 WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'CheckPayment')
					 AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'CKS')
					 AND MasterCompanyId = @masterCompanyId
					 AND DistributionSetupCode = 'CKSBANKACCOUNT';
			 END

			 SELECT  
					[ID]
					,[Name]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountId] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GLAccountId,0) ELSE [GlAccountId] END END AS [GlAccountId]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountName] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GlAccountName,0) ELSE [GlAccountName] END END AS [GlAccountName]
					,[JournalTypeId]
					,[DistributionMasterId]
					,[IsDebit]
					,[DisplayNumber]
					,[MasterCompanyId]
					,[CreatedBy]
					,[UpdatedBy]
					,[IsActive]
					,[IsDeleted]
					,ISNULL(UpdatedDate, GETUTCDATE()) UpdatedDate
					,ISNULL(CreatedDate, GETUTCDATE()) CreatedDate
					,CRDRType
					,CASE 
						WHEN CRDRType = 1 THEN 'DR'
						WHEN CRDRType = 0 THEN 'CR'
						WHEN CRDRType = 2 THEN 'DR/CR'
						ELSE '' END AS CRDRTypeName,
					 CASE WHEN ISNULL(IsManualText,0) = 1 THEN 0 ELSE ISNULL(IsManualText,0) END AS IsManualText,
					 ManualText,
					 IsAutoPost
				FROM dbo.DistributionSetup WITH (NOLOCK)
				WHERE IsDeleted = 0
					AND MasterCompanyId = @masterCompanyId
					AND JournalTypeId = @JournalTypeID 
			    ORDER BY DisplayNumber ASC 
		END
		--For CreditCard (Vendor Payment)
		IF(@JournalTypeCode = @CreditCardCode)
		BEGIN
			 SELECT @GLAccountId = [GLAccountId] FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityId] = @legalEntityId AND [IsPrimary] = 1;
			 
			 IF(ISNULL(@GLAccountId,0) > 0)
			 BEGIN
				  SELECT @GlAccountName = [AccountName], @GlAccountCode = [AccountCode] FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GLAccountId;
			 END

			 SELECT @DistributionSetupCode = [DistributionSetupCode], @DefaultGLAccountId = [GlAccountId] FROM [DBO].[DistributionSetup] WITH(NOLOCK) 
			 WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'CREDITCARDPAYMENT')
			 AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'CCP')
			 AND MasterCompanyId = @masterCompanyId
			 AND DistributionSetupCode = 'CCP-BANKACCOUNT';

			 --Update GL Account
			 IF(ISNULL(@GLAccountId,0) > 0 AND ISNULL(@DefaultGLAccountId,0) = 0)
			 BEGIN
				  UPDATE [DBO].[DistributionSetup] SET [GlAccountId] = @GLAccountId, [GlAccountName] = @GlAccountName, [GlAccountNumber] = @GlAccountCode
				  WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'CREDITCARDPAYMENT')
				  AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'CCP')
				  AND MasterCompanyId = @masterCompanyId
				  AND DistributionSetupCode = 'CCP-BANKACCOUNT';
			 END

			 SELECT  
					[ID]
					,[Name]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountId] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GLAccountId,0) ELSE [GlAccountId] END END AS [GlAccountId]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountName] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GlAccountName,0) ELSE [GlAccountName] END END AS [GlAccountName]
					,[JournalTypeId]
					,[DistributionMasterId]
					,[IsDebit]
					,[DisplayNumber]
					,[MasterCompanyId]
					,[CreatedBy]
					,[UpdatedBy]
					,[IsActive]
					,[IsDeleted]
					,ISNULL(UpdatedDate, GETUTCDATE()) UpdatedDate
					,ISNULL(CreatedDate, GETUTCDATE()) CreatedDate
					,CRDRType
					,CASE 
						WHEN CRDRType = 1 THEN 'DR'
						WHEN CRDRType = 0 THEN 'CR'
						WHEN CRDRType = 2 THEN 'DR/CR'
						ELSE '' END AS CRDRTypeName,
					 CASE WHEN ISNULL(IsManualText,0) = 1 THEN 0 ELSE ISNULL(IsManualText,0) END AS IsManualText,
					 ManualText,
					 IsAutoPost
				FROM dbo.DistributionSetup WITH (NOLOCK)
				WHERE IsDeleted = 0
					AND MasterCompanyId = @masterCompanyId
					AND JournalTypeId = @JournalTypeID 
			    ORDER BY DisplayNumber ASC 
		END
		ELSE
		--For ACH (Vendor Payment)
		IF(@JournalTypeCode = @ACHCode)
		BEGIN
			SELECT @GLAccountId = a.[GLAccountId]
			FROM [DBO].[ACH] AS A WITH(NOLOCK)
			LEFT JOIN [DBO].[GLAccount] AS GL WITH(NOLOCK) ON A.[GLAccountId] = GL.[GLAccountId]
			WHERE A.[LegalEntityId] = @LegalEntityId AND a.MasterCompanyId = @masterCompanyId
			 
			 IF(ISNULL(@GLAccountId,0) > 0)
			 BEGIN
				  SELECT @GlAccountName = [AccountName], @GlAccountCode = [AccountCode] FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GLAccountId;
			 END

			 SELECT @DistributionSetupCode = [DistributionSetupCode], @DefaultGLAccountId = [GlAccountId] FROM [DBO].[DistributionSetup] WITH(NOLOCK) 
			 WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'ACHTRANSFER')
			 AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'ACHT')
			 AND MasterCompanyId = @masterCompanyId
			 AND DistributionSetupCode = 'ACHT-BANKACCOUNT';

			 --Update GL Account
			 IF(ISNULL(@GLAccountId,0) > 0 AND ISNULL(@DefaultGLAccountId,0) = 0)
			 BEGIN
				  UPDATE [DBO].[DistributionSetup] SET [GlAccountId] = @GLAccountId, [GlAccountName] = @GlAccountName, [GlAccountNumber] = @GlAccountCode
				  WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'ACHTRANSFER')
				  AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'ACHT')
				  AND MasterCompanyId = @masterCompanyId
				  AND DistributionSetupCode = 'ACHT-BANKACCOUNT';
			 END

			 SELECT  
					[ID]
					,[Name]
					--,CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GLAccountId,0) ELSE [GlAccountId] END AS [GlAccountId]
					--,CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GlAccountName,0) ELSE [GlAccountName] END AS [GlAccountName]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountId] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GLAccountId,0) ELSE [GlAccountId] END END AS [GlAccountId]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountName] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GlAccountName,0) ELSE [GlAccountName] END END AS [GlAccountName]
					,[JournalTypeId]
					,[DistributionMasterId]
					,[IsDebit]
					,[DisplayNumber]
					,[MasterCompanyId]
					,[CreatedBy]
					,[UpdatedBy]
					,[IsActive]
					,[IsDeleted]
					,ISNULL(UpdatedDate, GETUTCDATE()) UpdatedDate
					,ISNULL(CreatedDate, GETUTCDATE()) CreatedDate
					,CRDRType
					,CASE 
						WHEN CRDRType = 1 THEN 'DR'
						WHEN CRDRType = 0 THEN 'CR'
						WHEN CRDRType = 2 THEN 'DR/CR'
						ELSE '' END AS CRDRTypeName,
					 CASE WHEN ISNULL(IsManualText,0) = 1 THEN 0 ELSE ISNULL(IsManualText,0) END AS IsManualText,
					 ManualText,
					 IsAutoPost
				FROM dbo.DistributionSetup WITH (NOLOCK)
				WHERE IsDeleted = 0
					AND MasterCompanyId = @masterCompanyId
					AND JournalTypeId = @JournalTypeID 
			    ORDER BY DisplayNumber ASC 
		END
		--For Wire (Vendor Payment)
		IF(@JournalTypeCode = @WireCode)
		BEGIN
			 --SELECT @GLAccountId = [GLAccountId] FROM [DBO].[InternationalWirePayment] WITH(NOLOCK) WHERE [LegalEntityId] = @legalEntityId AND [IsPrimary] = 1;
			 SELECT @GLAccountId = glac.[GLAccountId] FROM
				[DBO].[InternationalWirePayment] t WITH(NOLOCK)
			 INNER JOIN [DBO].[LegalEntityInternationalWireBanking] ad WITH(NOLOCK) ON t.[InternationalWirePaymentId] = ad.[InternationalWirePaymentId]
			 LEFT JOIN [DBO].[GLAccount] glac WITH(NOLOCK) ON t.[GLAccountId] = glac.[GLAccountId]
			 WHERE ad.[LegalEntityId] = @LegalEntityId AND t.MasterCompanyId = @masterCompanyId;
			 
			 IF(ISNULL(@GLAccountId,0) > 0)
			 BEGIN
				  SELECT @GlAccountName = [AccountName], @GlAccountCode = [AccountCode] FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GLAccountId;
			 END

			 SELECT @DistributionSetupCode = [DistributionSetupCode], @DefaultGLAccountId = [GlAccountId] FROM [DBO].[DistributionSetup] WITH(NOLOCK) 
			 WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'WIRETRANSFER')
			 AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'WRT')
			 AND MasterCompanyId = @masterCompanyId
			 AND DistributionSetupCode = 'WRT-BANKACCOUNT';

			 --Update GL Account
			 IF(ISNULL(@GLAccountId,0) > 0 AND ISNULL(@DefaultGLAccountId,0) = 0)
			 BEGIN
				  UPDATE [DBO].[DistributionSetup] SET [GlAccountId] = @GLAccountId, [GlAccountName] = @GlAccountName, [GlAccountNumber] = @GlAccountCode
				  WHERE DistributionMasterId = (SELECT [ID] FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'WIRETRANSFER')
				  AND [JournalTypeId] = (SELECT [ID] FROM [DBO].[JournalType] WHERE JournalTypeCode = 'WRT')
				  AND MasterCompanyId = @masterCompanyId
				  AND DistributionSetupCode = 'WRT-BANKACCOUNT';
			 END

			 SELECT  
					[ID]
					,[Name]
					--,CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GLAccountId,0) ELSE [GlAccountId] END AS [GlAccountId]
					--,CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GlAccountName,0) ELSE [GlAccountName] END AS [GlAccountName]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountId] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GLAccountId,0) ELSE [GlAccountId] END END AS [GlAccountId]
					,CASE WHEN ISNULL([GlAccountId],0) > 0 THEN [GlAccountName] ELSE CASE WHEN ISNULL(DistributionSetupCode,'') = @DistributionSetupCode THEN ISNULL(@GlAccountName,0) ELSE [GlAccountName] END END AS [GlAccountName]
					,[JournalTypeId]
					,[DistributionMasterId]
					,[IsDebit]
					,[DisplayNumber]
					,[MasterCompanyId]
					,[CreatedBy]
					,[UpdatedBy]
					,[IsActive]
					,[IsDeleted]
					,ISNULL(UpdatedDate, GETUTCDATE()) UpdatedDate
					,ISNULL(CreatedDate, GETUTCDATE()) CreatedDate
					,CRDRType
					,CASE 
						WHEN CRDRType = 1 THEN 'DR'
						WHEN CRDRType = 0 THEN 'CR'
						WHEN CRDRType = 2 THEN 'DR/CR'
						ELSE '' END AS CRDRTypeName,
					 CASE WHEN ISNULL(IsManualText,0) = 1 THEN 0 ELSE ISNULL(IsManualText,0) END AS IsManualText,
					 ManualText,
					 IsAutoPost
				FROM dbo.DistributionSetup WITH (NOLOCK)
				WHERE IsDeleted = 0
					AND MasterCompanyId = @masterCompanyId
					AND JournalTypeId = @JournalTypeID 
			    ORDER BY DisplayNumber ASC 
		END
		ELSE
		BEGIN
			 Select  
				 [ID]
				,[Name]  
				,[GlAccountId]  
				,[GlAccountName]  
				,[JournalTypeId]  
				,[DistributionMasterId]  
				,[IsDebit]  
				,[DisplayNumber]  
				,[MasterCompanyId]  
				,[CreatedBy]  
				,[UpdatedBy]  
				,[IsActive]  
				,[IsDeleted]  
				,isnull(UpdatedDate,GETUTCDATE()) as UpdatedDate  
				,isnull(CreatedDate,GETUTCDATE()) as CreatedDate 
				,CRDRType
				,CASE WHEN CRDRType=1 THEN 'DR'  
				 WHEN CRDRType=0 THEN 'CR'  
				 WHEN CRDRType=2 THEN 'DR/CR' ELSE '' END as 'CRDRTypeName',
				 ISNULL(IsManualText,0) IsManualText,
				 ManualText,
				 IsAutoPost
			 FROM dbo.DistributionSetup  WITH(NOLOCK)  
			 WHERE  IsDeleted = 0 and MasterCompanyId = @masterCompanyId and JournalTypeId= @JournalTypeID  order by DisplayNumber ASC 
		END
	END
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'GetDistributionSetupData'   
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@masterCompanyId, '') + ''  
        , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
        exec spLogException   
                @DatabaseName           =  @DatabaseName  
                , @AdhocComments          =  @AdhocComments  
                , @ProcedureParameters    =  @ProcedureParameters  
                , @ApplicationName        =  @ApplicationName  
                , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
        RETURN(1); 

	END CATCH

END