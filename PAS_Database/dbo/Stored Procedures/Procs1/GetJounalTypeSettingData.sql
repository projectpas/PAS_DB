/*************************************************************           
 ** File:   [GetJounalTypeSettingData]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for GetJounalTypeSettingData
 ** Purpose:         
 ** Date:   08/08/2022    
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    08/08/2022   Subhash Saliya		Created
    2    06/09/2024   Devendra Shekh		Modified to get Journal Details with Distribution Details

     
 EXECUTE [GetJounalTypeSettingData] 1
**************************************************************/ 

CREATE   PROCEDURE [dbo].[GetJounalTypeSettingData]
	@masterCompanyId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				IF OBJECT_ID('tempdb..#GLAllocationResults') IS NOT NULL
					DROP TABLE #GLAllocationResults

				CREATE TABLE #GLAllocationResults
				(
					[GlAllocationResultsId] BIGINT IDENTITY(1,1) NOT NULL,
					[SequenceNo] INT NULL,
					[JournalTypeID] BIGINT NULL,
					[JournalTypeCode] VARCHAR(50) NULL,
					[JournalTypeName] VARCHAR(200) NULL,
					[ID] BIGINT NULL,
					[IsEnforcePrint] BIT NULL,
					[IsAppendtoBatch] BIT NULL,
					[IsAutoPost] BIT NULL,
					[DistributionSetupID] BIGINT NULL,
					[Name] VARCHAR(200) NULL,
					[GlAccountId] BIGINT NULL,
					[GlAccountName] VARCHAR(200) NULL,
					[DistributionMasterId] BIGINT NULL,
					[IsDebit] BIT NULL,
					[DisplayNumber] INT NULL,
					[MasterCompanyId] INT NULL,
					[CreatedBy] VARCHAR(256) NULL,
					[UpdatedBy] VARCHAR(256) NULL,
					[IsActive] BIT NULL,
					[IsDeleted] BIT NULL,
					[UpdatedDate] DATETIME2 NULL,
					[CreatedDate] DATETIME2 NULL,
					[CRDRType] INT NULL,
					[CRDRTypeName] VARCHAR(30) NULL,
					[IsManualText] BIT NULL,
					[ManualText] VARCHAR(100) NULL,
				)

				;WITH JournalTypeData AS (
				SELECT	
					jt.JournalTypeCode,
					jt.ID as JournalTypeID,
                    jt.JournalTypeName,
                    jts.ID,
					jts.IsEnforcePrint,
                    jts.MasterCompanyId,
                    jts.CreatedBy,
                    jts.UpdatedBy,
                    isnull(jts.UpdatedDate,GETUTCDATE()) as UpdatedDate,
                    isnull(jts.CreatedDate,GETUTCDATE()) as CreatedDate,
                    jts.IsActive,
                    jts.IsDeleted,
					jts.IsAppendtoBatch,
					jts.IsAutoPost,
					SequenceNo
				FROM dbo.JournalType jt  WITH(NOLOCK)
				LEFT JOIN dbo.JournalTypeSetting jts   WITH(NOLOCK) on jt.ID=jts.JournalTypeID AND jts.MasterCompanyId= @masterCompanyId
				WHERE  jt.IsDeleted = 0)

				INSERT INTO #GLAllocationResults ( [JournalTypeCode], [JournalTypeName], [ID], [IsEnforcePrint], [IsAppendtoBatch], [IsAutoPost],
							[DistributionSetupID], [Name], [GlAccountId], [GlAccountName], [JournalTypeId], [DistributionMasterId], [IsDebit], [DisplayNumber], [MasterCompanyId], 
							[CreatedBy], [UpdatedBy], [IsActive], [IsDeleted], [UpdatedDate], [CreatedDate], [CRDRType], [CRDRTypeName], [IsManualText], [ManualText], [SequenceNo] )
				SELECT	[JournalTypeCode], [JournalTypeName], JTD.ID, [IsEnforcePrint], [IsAppendtoBatch], [IsAutoPost],
						DS.[ID], [Name], [GlAccountId], [GlAccountName], JTD.[JournalTypeId], [DistributionMasterId], [IsDebit], [DisplayNumber], JTD.[MasterCompanyId], 
						JTD.[CreatedBy], JTD.[UpdatedBy], JTD.[IsActive], JTD.[IsDeleted] ,isnull(JTD.UpdatedDate,GETUTCDATE()) as UpdatedDate ,isnull(JTD.CreatedDate,GETUTCDATE()) as CreatedDate,
						CRDRType,
						CASE	WHEN CRDRType=1 THEN 'DR' 
								WHEN CRDRType=0 THEN 'CR'
								WHEN CRDRType=2 THEN 'DR/CR' ELSE '' END as 'CRDRTypeName',
						ISNULL(IsManualText,0) IsManualText, ISNULL(ManualText, '') ManualText, [SequenceNo]
				FROM JournalTypeData JTD WITH(NOLOCK) 
				LEFT JOIN DistributionSetup DS ON DS.JournalTypeID = JTD.JournalTypeId AND DS.MasterCompanyId = JTD.MasterCompanyId;

				SELECT * FROM #GLAllocationResults ORDER BY [SequenceNo], [JournalTypeId] ASC;

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetJounalTypeSettingData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@masterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END