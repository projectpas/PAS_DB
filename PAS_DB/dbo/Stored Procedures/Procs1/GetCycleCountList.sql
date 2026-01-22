/*************************************************************           
 ** File:   [GetCycleCountList]           
 ** Author:   Moin Bloch
 ** Description: Get Search Data for Cycle Count List    
 ** Purpose:         
 ** Date: 11-11-2024
 ** PARAMETERS:               
 ** RETURN VALUE:    
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    11-11-2024   Moin Bloch        Created
	2    13-11-2024   Moin Bloch        Added Difference Amount New Field
	3    28-11-2024   Moin Bloch        Added New Field
	4    28-11-2024   Moin Bloch        Updated fixed Management Structuer duplicate issue
	5	 09/04/2025	  Ekta Chandegra	Convert date using dbo.ConvertUTCtoLocal

   EXEC [GetCycleCountList] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetCycleCountList]
@PageSize INT,
@PageNumber INT,
@SortColumn VARCHAR(50),
@SortOrder INT,
@GlobalFilter VARCHAR(50),
@CycleCountNumber VARCHAR(50) = NULL,
@Status VARCHAR(50) = NULL,
@EntryDate DATETIME = NULL,
@DifferenceAmount VARCHAR(50) = NULL,
@PostedDate DATETIME = NULL,
@BatchName VARCHAR(50) = NULL,
@CountMethod VARCHAR(20) = NULL,
@RequestedBy VARCHAR(100) = NULL,
@CountedBy VARCHAR(50) = NULL,
@ApprovedBy VARCHAR(50) = NULL,
@CurrentStockQuantity VARCHAR(50) = NULL,
@CountedQuantity VARCHAR(50) = NULL,
@DifferenceQuantity VARCHAR(50) = NULL,
@PartNumber VARCHAR(50) = NULL,
@PartDescription NVARCHAR(MAX) = NULL,
@ConditionName VARCHAR(50) = NULL,
@SerialNumber VARCHAR(50) = NULL,
@StockLineNumber varchar(50) = NULL,
@ControlNumber VARCHAR(50) = NULL,
@Site VARCHAR(50) = NULL,
@Warehouse VARCHAR(50) = NULL,
@Location VARCHAR(50) = NULL,
@Shelf VARCHAR(50) = NULL,
@Bin VARCHAR(50) = NULL,
@LastMSLevel VARCHAR(50) = NULL,     
@CreatedDate DATETIME = NULL,
@UpdatedDate DATETIME = NULL,
@IsDeleted BIT,	
@MasterCompanyId INT, 
@EmployeeId BIGINT,
@CycleCountFilter INT
AS
BEGIN
		SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId;

		DECLARE @RecordFrom INT;
		DECLARE @Count INT;
		DECLARE @MSModuleID INT; 
		DECLARE @ModuleID INT;
		SELECT @MSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'CycleCount'
				
        SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline'

		IF OBJECT_ID(N'tempdb..#tmpCycleCountUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpCycleCountUserRole
		END
		
		SELECT * INTO #tmpCycleCountUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].[ManagementStructureDetails] MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @MSModuleID AND EUR.[EmployeeId] = @EmployeeId) AS cyclecountUserRole
						
	
		SET @RecordFrom = (@PageNumber-1) * @PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF(UPPER(@Status)='ALL')
		BEGIN
			SET @Status = NULL;
		END		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CREATEDDATE')
		END 
		ELSE
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
		END				
		BEGIN TRY
			IF(@CycleCountFilter = 1)    
			BEGIN 
				;With Result AS(
					SELECT DISTINCT
					CCC.[CycleCountId], 
					CCC.[CycleCountNumber],
					CCC.[StatusId],
					CCS.[Status],					
					(Cast(DBO.ConvertUTCtoLocal(CCC.[EntryDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as EntryDate,
					ISNULL(SUM(ABS(CCD.[DifferenceAmount])),0) AS [DifferenceAmount],
					(Cast(DBO.ConvertUTCtoLocal(CCC.[PostedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as PostedDate,
					CCC.[BatchName],
					CASE WHEN CCC.[CountMethodId] = 1 THEN 'Online' WHEN CCC.[CountMethodId] = 2 THEN 'Manual' ELSE '' END [CountMethod],
					(Cast(DBO.ConvertUTCtoLocal(CCC.[CreatedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate,
					(Cast(DBO.ConvertUTCtoLocal(CCC.[UpdatedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate,
					ISNULL(CCE.[FirstName],'') + ' ' + ISNULL(CCE.[LastName],'') AS [RequestedBy],
					ISNULL(CEE.[FirstName],'') + ' ' + ISNULL(CEE.[LastName],'') AS [CountedBy],					
					ISNULL(CEA.[FirstName],'') + ' ' + ISNULL(CEA.[LastName],'') AS [ApprovedBy],					
					ISNULL(SUM(CCD.[CurrentStockQuantity]),0) AS [CurrentStockQuantity],			
					ISNULL(SUM(CCD.[CountedQuantity]),0) [CountedQuantity],					
					ISNULL(SUM(ABS(CCD.[DifferenceQuantity])),0) [DifferenceQuantity],
					CCC.[IsActive],
					CCC.[IsDeleted]										
				FROM [dbo].[CycleCount] CCC WITH (NOLOCK)
				     LEFT JOIN [dbo].[CycleCountDetail] CCD WITH(NOLOCK) ON CCC.[CycleCountId] = CCD.[CycleCountId]
					 LEFT JOIN [dbo].[CycleCountApproval] CCA WITH(NOLOCK) ON CCD.[CycleCountDetailId] = CCA.[CycleCountDetailId]
					INNER JOIN [dbo].[CycleCountStatus] CCS WITH(NOLOCK) ON CCC.[StatusId] = CCS.[CycleCountStatusId]
					INNER JOIN [dbo].[Employee] CCE WITH(NOLOCK) ON CCC.[RequestedById] = CCE.[EmployeeId]
					 LEFT JOIN [dbo].[Employee] CEE WITH(NOLOCK) ON CCC.[CountedById] = CEE.[EmployeeId]
					 LEFT JOIN [dbo].[Employee] CEA WITH(NOLOCK) ON CCA.[ApprovedById] = CEA.[EmployeeId]
				   INNER JOIN #tmpCycleCountUserRole CCR ON CCR.[ReferenceID] = CCC.[CycleCountId]
					--INNER JOIN [dbo].[ManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @MSModuleID AND MSD.[ReferenceID] = CCC.[CycleCountId]
					--INNER JOIN [dbo].[RoleManagementStructure] RMS WITH(NOLOCK) ON CCC.[ManagementStructureId] = RMS.[EntityStructureId]
					--INNER JOIN [dbo].[EmployeeUserRole] EUR WITH(NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId
				WHERE (CCC.[MasterCompanyId] = @MasterCompanyId AND CCC.[IsActive] = 1 AND CCC.[IsDeleted] = @IsDeleted)		
				GROUP BY CCC.[CycleCountId],CCC.[CycleCountNumber],CCC.[StatusId],CCS.[Status],CCC.[EntryDate],CCC.[PostedDate],CCC.[BatchName],CCC.[CountMethodId],
					CCC.[CreatedDate],CCC.[UpdatedDate],CCC.[IsActive],CCC.[IsDeleted],CCE.[FirstName],CCE.[LastName],CEE.[FirstName],CEE.[LastName],
					CEA.[FirstName],CEA.[LastName]
				), ResultCount AS(SELECT COUNT([CycleCountId]) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE ((@GlobalFilter <>'' AND (([CycleCountNumber] LIKE '%' +@GlobalFilter+'%' ) OR 					
					([Status] LIKE '%' + @GlobalFilter+'%') OR
					([DifferenceAmount] LIKE '%' +@GlobalFilter+'%') OR
					([BatchName] LIKE '%' +@GlobalFilter+'%') OR
					([CountMethod] LIKE '%' +@GlobalFilter+'%') OR					
					([RequestedBy] LIKE '%' +@GlobalFilter+'%') OR
					([CountedBy] LIKE '%' +@GlobalFilter+'%') OR
					([ApprovedBy] LIKE '%' +@GlobalFilter+'%') OR
					([CurrentStockQuantity] LIKE '%' +@GlobalFilter+'%') OR
					([CountedQuantity] LIKE '%' +@GlobalFilter+'%') OR
					([DifferenceQuantity] LIKE '%' +@GlobalFilter+'%') 										
					))
					OR   
					(@GlobalFilter='' AND (ISNULL(@CycleCountNumber,'') ='' OR CycleCountNumber LIKE '%' + @CycleCountNumber+'%') AND 
					(ISNULL(@Status,'') ='' OR [Status] LIKE '%' + @Status+'%') AND
					(ISNULL(@EntryDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal([EntryDate],@CurrntEmpTimeZoneDesc) AS DATE)) = CAST(@EntryDate AS DATE)) AND
					(IsNull(@DifferenceAmount,'') ='' OR CAST([DifferenceAmount] AS VARCHAR(50)) LIKE '%' + @DifferenceAmount+'%' ) AND     
					(ISNULL(@PostedDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal([PostedDate],@CurrntEmpTimeZoneDesc) AS DATE)) = CAST(@PostedDate AS DATE)) AND
					(ISNULL(@BatchName,'') ='' OR [BatchName] LIKE '%' + @BatchName+'%') AND
					(ISNULL(@CountMethod,'') ='' OR [CountMethod] LIKE '%' + @CountMethod+'%') AND
					(ISNULL(@CountedBy,'') ='' OR [CountedBy] LIKE '%' + @CountedBy+'%') AND
					(ISNULL(@ApprovedBy,'') ='' OR [ApprovedBy] LIKE '%' + @ApprovedBy +'%') AND
					(ISNULL(@CreatedDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal([CreatedDate],@CurrntEmpTimeZoneDesc) AS DATE)) = CAST(@CreatedDate AS DATE)) AND
					(ISNULL(@UpdatedDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal([UpdatedDate],@CurrntEmpTimeZoneDesc) AS DATE)) = CAST(@UpdatedDate AS DATE)) AND
					(ISNULL(@RequestedBy,'') ='' OR [RequestedBy] LIKE '%' + @RequestedBy +'%') AND
					(ISNULL(@CurrentStockQuantity,'') ='' OR [CurrentStockQuantity] LIKE '%' + @CurrentStockQuantity +'%') AND
					(ISNULL(@CountedQuantity,'') ='' OR [CountedQuantity] LIKE '%' + @CountedQuantity +'%') AND
					(ISNULL(@DifferenceQuantity,'') ='' OR [DifferenceQuantity] LIKE '%' + @DifferenceQuantity +'%')))

				SELECT @Count = COUNT([CycleCountId]) FROM #TempResult			

				SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			
				CASE WHEN (@SortOrder=1 AND @SortColumn='CYCLECOUNTNUMBER')  THEN [CycleCountNumber] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='STATUS')  THEN [Status] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='ENTRYDATE')  THEN [EntryDate] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='DIFFERENCEAMOUNT')  THEN [DifferenceAmount] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='POSTEDDATE')  THEN [PostedDate] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNAME')  THEN [BatchName] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='COUNTMETHOD')  THEN [CountMethod] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='COUNTEDBY')  THEN [CountedBy] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='APPROVEDBY')  THEN [ApprovedBy] END ASC,				
				CASE WHEN (@SortOrder=1 AND @SortColumn='REQUESTEDBY')  THEN [RequestedBy] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CURRENTSTOCKQUANTITY')  THEN [CurrentStockQuantity] END ASC,				
				CASE WHEN (@SortOrder=1 AND @SortColumn='COUNTEDQUANTITY')  THEN [CountedQuantity] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='DIFFERENCEQUANTITY')  THEN [DifferenceQuantity] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN [UpdatedDate] END ASC,
								   			 
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CYCLECOUNTNUMBER')  THEN [CycleCountNumber] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='STATUS') THEN [Status] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ENTRYDATE')  THEN [EntryDate] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DIFFERENCEAMOUNT')  THEN [DifferenceAmount] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='POSTEDDATE')  THEN [PostedDate] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNAME')  THEN [BatchName] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='COUNTMETHOD')  THEN [CountMethod] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='COUNTEDBY')  THEN [CountedBy] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='APPROVEDBY')  THEN [ApprovedBy] END DESC,				
				CASE WHEN (@SortOrder=-1 AND @SortColumn='REQUESTEDBY')  THEN [RequestedBy] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENTSTOCKQUANTITY')  THEN [CurrentStockQuantity] END DESC,				
				CASE WHEN (@SortOrder=-1 AND @SortColumn='COUNTEDQUANTITY')  THEN [CountedQuantity] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DIFFERENCEQUANTITY')  THEN [DifferenceQuantity] END DESC,			
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN [UpdatedDate] END DESC

				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE 
		BEGIN
			;With Result AS(
					SELECT DISTINCT
					CCC.[CycleCountId], 
					CCC.[CycleCountNumber],
					CCC.[StatusId],
					CCS.[Status],
					ITM.[partnumber] AS PartNumber,
					ITM.[PartDescription],
					CCC.[PostedDate],
					CCC.[BatchName],
					CCD.[ConditionName],
					CCD.[SerialNumber],
					CCD.[StockLineNumber],
					CCD.[ControlNumber],
					ISNULL(CCD.[CurrentStockQuantity],0) AS [CurrentStockQuantity],	
					ISNULL(CCD.[CountedQuantity],0) AS [CountedQuantity],	
					ISNULL(ABS(CCD.[DifferenceQuantity]),0) AS [DifferenceQuantity],
					CCD.[Site],
					CCD.[Warehouse],
					CCD.[Location],
					CCD.[Shelf],
					CCD.[Bin],
					MSD.[LastMSLevel],
			        MSD.[AllMSlevels],
					CCC.[CreatedDate]
				FROM [dbo].[CycleCount] CCC WITH (NOLOCK)
				    INNER JOIN [dbo].[CycleCountDetail] CCD WITH (NOLOCK) ON CCC.[CycleCountId] = CCD.[CycleCountId]
					INNER JOIN [dbo].[ItemMaster] ITM WITH (NOLOCK) ON CCD.[ItemMasterId] = ITM.[ItemMasterId]
					INNER JOIN [dbo].[CycleCountStatus] CCS WITH (NOLOCK) ON CCC.[StatusId] = CCS.[CycleCountStatusId]					
					INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = CCD.[StockLineId]
					INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON CCC.[ManagementStructureId] = RMS.[EntityStructureId]
					INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND EUR.[EmployeeId] = @EmployeeId		            
				WHERE (CCC.[MasterCompanyId] = @MasterCompanyId AND CCC.[IsActive] = 1 AND CCC.[IsDeleted] = @IsDeleted)		
				
				), ResultCount AS(SELECT COUNT([CycleCountId]) AS totalItems FROM Result)
			SELECT * INTO #TempResult2 FROM  Result
			WHERE ((@GlobalFilter <>'' AND (([CycleCountNumber] LIKE '%' +@GlobalFilter+'%' ) OR 					
					([partnumber] LIKE '%' +@GlobalFilter+'%') OR
					([PartDescription] LIKE '%' +@GlobalFilter+'%') OR
					([BatchName] LIKE '%' +@GlobalFilter+'%') OR
					([ConditionName] LIKE '%' +@GlobalFilter+'%') OR
					([SerialNumber] LIKE '%' +@GlobalFilter+'%') OR
					([StockLineNumber] LIKE '%' +@GlobalFilter+'%') OR
					([ControlNumber] LIKE '%' +@GlobalFilter+'%') OR					
					([CurrentStockQuantity] LIKE '%' +@GlobalFilter+'%') OR
					([CountedQuantity] LIKE '%' +@GlobalFilter+'%') OR
					([DifferenceQuantity] LIKE '%' +@GlobalFilter+'%') OR
					([Site] LIKE '%' +@GlobalFilter+'%') OR
					([Warehouse] LIKE '%' +@GlobalFilter+'%') OR
					([Location] LIKE '%' +@GlobalFilter+'%') OR
					([Shelf] LIKE '%' +@GlobalFilter+'%') OR
					([Bin] LIKE '%' +@GlobalFilter+'%')	OR	
					([LastMSLevel] LIKE '%' +@GlobalFilter+'%')												
					))
					OR   
					(@GlobalFilter='' AND (ISNULL(@CycleCountNumber,'') ='' OR CycleCountNumber LIKE '%' + @CycleCountNumber+'%') AND 
					(ISNULL(@PartNumber,'') ='' OR [partnumber] LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@Status,'') ='' OR [Status] LIKE '%' + @Status+'%') AND
					(ISNULL(@PartDescription,'') ='' OR [PartDescription] LIKE '%' + @PartDescription+'%') AND
					(ISNULL(@ConditionName,'') ='' OR [ConditionName] LIKE '%' + @ConditionName+'%') AND
					(ISNULL(@SerialNumber,'') ='' OR [SerialNumber] LIKE '%' + @SerialNumber+'%') AND
					(ISNULL(@StockLineNumber,'') ='' OR [StockLineNumber] LIKE '%' + @StockLineNumber+'%') AND
					(ISNULL(@ControlNumber,'') ='' OR [ControlNumber] LIKE '%' + @ControlNumber+'%') AND
					(ISNULL(@CurrentStockQuantity,'') ='' OR [CurrentStockQuantity] LIKE '%' + @CurrentStockQuantity +'%') AND
					(ISNULL(@CountedQuantity,'') ='' OR [CountedQuantity] LIKE '%' + @CountedQuantity +'%') AND
					(ISNULL(@DifferenceQuantity,'') ='' OR [DifferenceQuantity] LIKE '%' + @DifferenceQuantity +'%') AND
					(ISNULL(@PostedDate,'') ='' OR CAST([PostedDate] AS DATE) = CAST(@PostedDate AS DATE)) AND
					(ISNULL(@BatchName,'') ='' OR [BatchName] LIKE '%' + @BatchName+'%') AND
					(ISNULL(@Site,'') ='' OR [Site] LIKE '%' + @Site+'%') AND
					(ISNULL(@Warehouse,'') ='' OR [Warehouse] LIKE '%' + @Warehouse+'%') AND
					(ISNULL(@Location,'') ='' OR [Location] LIKE '%' + @Location+'%') AND
					(ISNULL(@Shelf,'') ='' OR [Shelf] LIKE '%' + @Shelf+'%') AND
					(ISNULL(@Bin,'') ='' OR [Bin] LIKE '%' + @Bin+'%') AND
					(ISNULL(@LastMSLevel,'') ='' OR [LastMSLevel] LIKE '%' + @LastMSLevel+'%')))

				SELECT @Count = COUNT([CycleCountId]) FROM #TempResult2			

				SELECT *, @Count AS [NumberOfItems] FROM #TempResult2 ORDER BY  
			
				CASE WHEN (@SortOrder=1 AND @SortColumn='CYCLECOUNTNUMBER')  THEN [CycleCountNumber] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN [partnumber] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN [PartDescription] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CONDITIONNAME')  THEN [ConditionName] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SERIALNUMBER')  THEN [SerialNumber] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='STOCKLINENUMBER')  THEN [StockLineNumber] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CONTROLNUMBER')  THEN [ControlNumber] END ASC,				
				CASE WHEN (@SortOrder=1 AND @SortColumn='CURRENTSTOCKQUANTITY') THEN [CurrentStockQuantity] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='COUNTEDQUANTITY')  THEN [CountedQuantity] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='DIFFERENCEQUANTITY')  THEN [DifferenceQuantity] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='POSTEDDATE')  THEN [PostedDate] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNAME')  THEN [BatchName] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SITE')  THEN [Site] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='WAREHOUSE')  THEN [Warehouse] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='LOCATION')  THEN [Location] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SHELF')  THEN [Shelf] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='BIN')  THEN [Bin] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='LASTMSLEVEL')  THEN [Bin] END ASC,				
				CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END ASC,
								   			 
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CYCLECOUNTNUMBER')  THEN [CycleCountNumber] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN [partnumber] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN [PartDescription] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CONDITIONNAME')  THEN [ConditionName] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUMBER')  THEN [SerialNumber] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='STOCKLINENUMBER')  THEN [StockLineNumber] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTROLNUMBER')  THEN [ControlNumber] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENTSTOCKQUANTITY')  THEN [CurrentStockQuantity] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='COUNTEDQUANTITY')  THEN [CountedQuantity] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DIFFERENCEQUANTITY')  THEN [DifferenceQuantity] END DESC,	
				CASE WHEN (@SortOrder=-1 AND @SortColumn='POSTEDDATE')  THEN [PostedDate] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNAME')  THEN [BatchName] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SITE')  THEN [Site] END DESC,		
				CASE WHEN (@SortOrder=-1 AND @SortColumn='WAREHOUSE')  THEN [Warehouse] END DESC,		
				CASE WHEN (@SortOrder=-1 AND @SortColumn='LOCATION')  THEN [Location] END DESC,		
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SHELF')  THEN [Shelf] END DESC,		
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BIN')  THEN [Bin] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTMSLEVEL')  THEN [Bin] END DESC,	
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN [CreatedDate] END DESC
									
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY		
		END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0					
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              ,@AdhocComments     VARCHAR(150)    = 'GetCycleCountList' 
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))  							
              ,@ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH  	
END