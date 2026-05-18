/*************************************************************           
 ** File:   [GetWorkFlowList]           
 ** Author:   Hemant Saliya
 ** Description: Get Search Data for Work Flow List    
 ** Purpose:         
 ** Date:   19-Dec-2020        
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/19/2020   Hemant Saliya Created
	2    04/21/2021   Added Try-catch blocks , Transation & Rollback
	3    04/28/2021   Added Content Managment for DB Logs
	4    08/02/2021   Added Is Verion Increase flag
	5    11/03/2025   Sahdev Saliya  Added New Field TemplateDescription
	6    20/03/2025   Ekta Chandegra Convert date using dbo.ConvertUTCtoLocal
	7    18-04-2025   Shrey Chandegara  Modifed due to datefilter issue
	8    02-08-2025   Sahdev Saliya   Added New Field Verified, VerifiedBy And VerifiedDate
	9    24-04-2026   Priyansh Patel   Added New Field TemplateType [PN-16166]
	10   04-05-2026   Priyansh Patel   Added New Field TemplateType [PN-16166]
	11   07-05-2026   Priyansh Patel   Global filter updated [PN-16341]
	12   18-05-2026   Priyansh Patel   Updated maintenance type and Work scope return column [PN-16419]

exec GetWorkFlowList @PageSize=20,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@GlobalFilter=N'',@WorkOrderNumber=NULL,@Version=NULL,@PartNumber=NULL,@PartDescription=NULL,@ManufacturerName=NULL,@WorkScopeCode=NULL,@CustomerName=NULL,@WorkflowCreateDate=NULL,@WorkflowExpirationDate=NULL,@CreatedDate=NULL,@UpdatedDate=NULL,@CreatedBy=NULL,@UpdatedBy=NULL,@IsDeleted=0,@MasterCompanyId=1,@TemplateDescription=NULL,@EmployeeId=223
**************************************************************/ 

CREATE    PROCEDURE [dbo].[GetWorkFlowList]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@WorkOrderNumber varchar(50)=null,
	@Version varchar(50)=null,
	@PartNumber varchar(50)=null,
	@PartDescription varchar(50)=null,
	@ManufacturerName varchar(50)=null,
	@WorkScopeCode varchar(50)=null,
	@CustomerName varchar(50)=null,	
	@WorkflowCreateDate datetime=null,
	@WorkflowExpirationDate datetime=null,	
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@MasterCompanyId int,
	@TemplateDescription varchar(500)=null,
	@AcTemplate bit =null,
	@TailNumber varchar(100)=null,
	@SerialNum varchar(100)=null,
	@AircraftModel	varchar(100) = NULL,
	@AircraftMake	varchar(100) = NULL,
	@MaintenanceType varchar(100) = NULL,
	@EmployeeId bigint

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
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
				
		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
		Declare @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted is null
		Begin
			Set @IsDeleted=0
		End
		IF @SortColumn is null
		Begin
			Set @SortColumn=Upper('CreatedDate')
		End 
		Else
		Begin 
			Set @SortColumn=Upper(@SortColumn)
		End

		If @StatusID=0
		Begin 
			Set @IsActive=0
		End 
		else IF @StatusID=1
		Begin 
			Set @IsActive=1
		End 
		else IF @StatusID=2
		Begin 
			Set @IsActive=null
		End 

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				;With Result AS(
					SELECT	
					wf.WorkflowId, 					
					ws.WorkScopeCode As WorkScopeCode,
					wf.WorkScopeId,
					c.Name,
					im.PartNumber,	
				    UPPER(wf.WorkflowDescription) 'templateDescription',
					im.PartDescription,
					wf.WorkOrderNumber,
					wf.WorkflowExpirationDate AS WorkflowExpirationDate,
					wf.WorkflowCreateDate AS WorkflowCreateDate,
					wf. Version,
					wf.OtherCost,
					wf.ItemMasterId,
					wf.ChangedPartNumberId,
					cp.partnumber AS  ChangedPartNumber,
					cp.PartDescription AS ChangedPartNumberDescription,					
					wf.Memo,

					wf.IsActive,
					wf.IsDeleted,
					(Cast(DBO.ConvertUTCtoLocal(wf.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) CreatedDate,
					wf.CreatedBy,
					(Cast(DBO.ConvertUTCtoLocal(wf.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) UpdatedDate,
					wf.UpdatedBy,
					CASE WHEN wf.IsVersionIncrease IS NULL THEN CASE WHEN WFParentId IS NULL THEN 0 ELSE 1 END ELSE wf.IsVersionIncrease END AS IsVersionIncrease
					,im.ManufacturerName ManufacturerName,
					wf.TemplateType,
					wf.TailNum AS AcTailNumber,
					wf.SerialNum AS AcSerialNumber,
					ACM.ModelName AS AircraftModel,
					ACT.[Description] AS AircraftMake, 
					MT.[MaintenanceType] AS MaintenanceType,
					wf.Verified,
					wf.VerifiedBy,
					wf.VerifiedDate
					FROM Workflow wf WITH (NOLOCK)
					LEFT  JOIN dbo.WorkScope ws WITH (NOLOCK) on wf.WorkScopeId = ws.WorkScopeId
					LEFT JOIN dbo.Customer c WITH (NOLOCK) on c.CustomerId =  wf.CustomerId
					LEFT JOIN dbo.ItemMaster im WITH (NOLOCK) on im.ItemMasterId =  wf.ItemMasterId
					LEFT JOIN dbo.ItemMaster cp WITH (NOLOCK) on cp.ItemMasterId =  wf.ChangedPartNumberId
					LEFT JOIN dbo.AircraftModel ACM WITH (NOLOCK) on ACM.AircraftModelId =  wf.AircraftModelId
					LEFT JOIN dbo.AircraftType ACT WITH (NOLOCK) on ACT.AircraftTypeId =  wf.MakeTypeId
					LEFT JOIN dbo.MaintenanceType MT WITH (NOLOCK) on MT.MaintenanceTypeId =  wf.MaintenanceTypeId
					WHERE ((ISNULL(wf.IsDeleted, 0) = @IsDeleted) and (@IsActive is null or wf.IsActive=@IsActive))
					AND wf.MasterCompanyId=@MasterCompanyId	
			), ResultCount AS(Select COUNT(WorkflowId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE (
			(@GlobalFilter <>'' AND ((WorkOrderNumber like '%' +@GlobalFilter+'%' ) OR 
					(Version like '%' +@GlobalFilter+'%') OR
					(PartNumber like '%' +@GlobalFilter+'%') OR					
					(PartDescription like '%' +@GlobalFilter+'%') OR
					(ManufacturerName like '%' +@GlobalFilter+'%') OR
					(WorkScopeCode like '%' +@GlobalFilter+'%') OR
					(Name like '%' +@GlobalFilter+'%') OR
					(CreatedBy like '%' +@GlobalFilter+'%') OR
					(UpdatedBy like '%' +@GlobalFilter+'%') 
					)
					AND (@AcTemplate IS NULL OR TemplateType = CASE WHEN @AcTemplate = 1 THEN 2 ELSE 1 END)
					)
					OR   
					(@GlobalFilter='' AND (IsNull(@WorkOrderNumber,'') ='' OR WorkOrderNumber like '%' + @WorkOrderNumber+'%') and 
					(IsNull(@Version,'') ='' OR Version like '%' + @Version+'%') and
					(IsNull(@PartNumber,'') ='' OR partnumber like '%' + @PartNumber+'%') and
					(IsNull(@TemplateDescription,'') ='' OR TemplateDescription like '%' + @TemplateDescription+'%') and
					(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') and
					(IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') and
					(IsNull(@WorkScopeCode,'') ='' OR WorkScopeCode like '%' + @WorkScopeCode+'%') and
					(IsNull(@CustomerName,'') ='' OR Name like '%' + @CustomerName+'%') and
					(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') and
					(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') and
					(IsNull(@WorkflowCreateDate,'') ='' OR Cast(WorkflowCreateDate as Date)=Cast(@WorkflowCreateDate as date)) and
					(IsNull(@WorkflowExpirationDate,'') ='' OR Cast(WorkflowExpirationDate as Date)=Cast(@WorkflowExpirationDate as date)) and
					(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
					--(IsNull(@CreatedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc)AS DATE)=CAST(@CreatedDate AS DATE)) and
					--(IsNull(@UpdatedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATE)=CAST(@UpdatedDate AS DATE))
					(IsNull(@TailNumber,'') ='' OR AcTailNumber like '%' + @TailNumber+'%') and
					(IsNull(@SerialNum,'') ='' OR AcSerialNumber like '%' + @SerialNum+'%') and
					(IsNull(@AircraftModel,'') ='' OR AircraftModel like '%' + @AircraftModel+'%') and
					(IsNull(@AircraftMake,'') ='' OR AircraftMake like '%' + @AircraftMake+'%') and
					(IsNull(@MaintenanceType,'') ='' OR MaintenanceType like '%' + @MaintenanceType+'%') and
					(@AcTemplate IS NULL OR TemplateType = CASE WHEN @AcTemplate = 1 THEN 2 ELSE 1 END) and
					(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as Date)=Cast(@UpdatedDate as date)))
					)
			
			SELECT @Count = COUNT(WorkflowId) from #TempResult			

			SELECT *, @Count As NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUMBER')  THEN WorkOrderNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='VERSION')  THEN Version END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN partnumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='DESCRIPTION')  THEN WorkScopeCode END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='NAME')  THEN Name END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKFLOWCREATEDATE')  THEN WorkflowCreateDate END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKFLOWEXPIRATIONDATE')  THEN WorkflowExpirationDate END ASC,
            CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURERNAME')  THEN ManufacturerName END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='TEMPLATEDESCRIPTION')  THEN TemplateDescription END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ACTAILNUMBER')  THEN AcTailNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ACSERIALNUMBER')  THEN AcSerialNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='AIRCRAFTMODEL')  THEN AircraftModel END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='AIRCRAFTMAKE')  THEN AircraftMake END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='MAINTENANCETYPE')  THEN MaintenanceType END ASC,

			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUMBER')  THEN WorkOrderNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='VERSION')  THEN Version END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN partnumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='DESCRIPTION')  THEN WorkScopeCode END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='NAME')  THEN Name END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKFLOWCREATEDATE')  THEN WorkflowCreateDate END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKFLOWEXPIRATIONDATE')  THEN WorkflowExpirationDate END DESC,
            CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURERNAME')  THEN ManufacturerName END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='TEMPLATEDESCRIPTION')  THEN TemplateDescription END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ACTAILNUMBER')  THEN AcTailNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ACSERIALNUMBER')  THEN AcSerialNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='AIRCRAFTMODEL')  THEN AircraftModel END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='AIRCRAFTMAKE')  THEN AircraftMake END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='MAINTENANCETYPE')  THEN MaintenanceType END DESC





			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY

			END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkFlowList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@StatusID,'') + ', 
													   @Parameter6 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter7 = ' + ISNULL(@WorkOrderNumber,'') + ', 
													   @Parameter8 = ' + ISNULL(@Version,'') + ', 
													   @Parameter9 = ' + ISNULL(@PartNumber,'') + ', 
													   @Parameter10 = ' + ISNULL(@PartDescription,'') + ', 
													   @Parameter11 = ' + ISNULL(@WorkScopeCode,'') + ', 
													   @Parameter12 = ' + ISNULL(@CustomerName,'') + ', 
													   @Parameter13 = ' + ISNULL(@WorkflowCreateDate,'') + ', 
													   @Parameter14 = ' + ISNULL(@WorkflowExpirationDate,'') + ', 
													   @Parameter15 = ' + ISNULL(@CreatedDate,'') + ', 
													   @Parameter16 = ' + ISNULL(@UpdatedDate,'') + ', 
													   @Parameter17 = ' + ISNULL(@CreatedBy,'') + ', 
													   @Parameter18 = ' + ISNULL(@UpdatedBy,'') + ', 
													   @Parameter19 = ' + ISNULL(@IsDeleted,'') + ', 
													   @Parameter20 = ' + ISNULL(@MasterCompanyId ,'') +''
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