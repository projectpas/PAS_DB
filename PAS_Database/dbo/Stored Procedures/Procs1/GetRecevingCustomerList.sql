
/*************************************************************           
 ** File:   [GetRecevingCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Get Search Data for Receving Customer List    
 ** Purpose:         
 ** Date:   29-Dec-2020        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2020   Hemant Saliya Created
	2    04/28/2021   Hemant Saliya Added Content Managment for DB Logs
	3    01/01/2021   Hemant Saliya Added Delete And IsActive Condition
	4    03/19/2024   Hemant Saliya Updated Cust Refrence as RO Number
     
 EXECUTE [GetRecevingCustomerList] 100, 1, null, -1, 1, '', null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,null,null,null,0,1,1 
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetRecevingCustomerList]
	-- Add the parameters for the stored procedure here	
	@PageSize int,
	@PageNumber int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@GlobalFilter varchar(50) = null,
	@CustomerName varchar(50)=null,
	@PartNumber varchar(50)=null,
	@PartDescription varchar(50)=null,
	@SerialNumber varchar(50)=null,	
    @WONumber varchar(50)=null,
    @ReceivingNumber varchar(50)=null,
    @ReceivedDate datetime=null,
    @ReceivedBy varchar(200)=null,
    @LastMSLevel varchar(50)=null,
    @StageCode varchar(50)=null,
	@Status varchar(50)=null,
	@WOFilter varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,	
	@MasterCompanyId bigint, 
	@EmployeeId bigint,
	@StocklineNumber varchar(50)=null,
	@ControlNumber varchar(50)=null,
	@IdNumber varchar(50)=null

AS
BEGIN
		SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;
		DECLARE @MSModuleID INT = 1; -- Receving Customer Management Structure Module ID

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN

				;With Result AS(
					Select	DISTINCT
					RC.CustomerId, 
					RC.ReceivingCustomerWorkId,
					RC.ReceivedDate,
					RC.ReceivingNumber,
					RC.StockLineId,
					SL.QuantityAvailable,
					SL.QuantityOnHand,
					SL.StocklineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					IM.partnumber AS PartNumber,
					M.Name As Manufacturer,
					IM.PartDescription,
					RC.CustomerName,
					WOS.Stage AS StageCode,
					WOST.Description AS Status,
					RC.ManagementStructureId,
					RC.SerialNumber,
					CASE WHEN @WOFilter = 1 THEN NULL
						 WHEN @WOFilter = 2 AND wo.WorkOrderStatusId = 2 THEN WO.WorkOrderNum
						 ELSE WO.WorkOrderNum
					END AS WorkOrderNum,
					CASE WHEN @WOFilter = 1 THEN NULL
						 WHEN @WOFilter = 2 AND wo.WorkOrderStatusId = 2 THEN WO.OpenDate
						 ELSE WO.OpenDate
					END AS WOOpenDate,
					WO.WorkOrderNum AS WONumber,
					--RO.RepairOrderNumber AS RONumber,
					RC.Reference AS RONumber,
					ROP.RepairOrderPartRecordId,
					RC.EmployeeName AS ReceivedBy,
					RC.ManagementStructureId AS Ids,
					RC.IsActive,
					RC.IsDeleted,
					RC.CreatedDate,
					RC.CreatedBy,
					RC.UpdatedDate,
					RC.UpdatedBy, 
					MSD.LastMSLevel,
					MSD.AllMSlevels
				FROM dbo.ReceivingCustomerWork RC WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON RC.ItemMasterId = IM.ItemMasterId
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = rc.ReceivingCustomerWorkId
					INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
					INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					INNER JOIN dbo.Stockline SL WITH (NOLOCK) ON RC.StockLineId = SL.StockLineId
					LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
					LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON RC.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
					LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
					LEFT JOIN dbo.ItemMaster RP WITH (NOLOCK) ON RC.RevisePartId = RP.RevisedPartId
					LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON RC.WorkOrderId = WO.WorkOrderId
					LEFT JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON RC.StockLineId = WOP.StockLineId
					LEFT JOIN dbo.WorkOrderStage WOS WITH (NOLOCK) ON WOP.WorkOrderStageId = WOS.WorkOrderStageId
					LEFT JOIN dbo.WorkOrderStatus WOST WITH (NOLOCK) ON WOP.WorkOrderStageId = WOST.Id					
				WHERE (RC.MasterCompanyId = @MasterCompanyId AND RC.IsActive = 1 AND RC.IsDeleted = 0
						AND ((@WOFilter = 1 AND ((WO.WorkOrderNum IS NUll OR WO.WorkOrderNum = '') AND (RO.RepairOrderNumber IS NULL OR RO.RepairOrderNumber = ''))) 
						OR (@WOFilter = 2 AND WO. WorkOrderNum IS NOT NUll AND WO.WorkOrderStatusId = 2 ) 
						OR (@WOFilter = 3 AND (WO.WorkOrderNum IS NOT NUll OR WO.WorkOrderNum IS NUll OR RO.RepairOrderNumber IS NOT NULL OR RO.RepairOrderNumber IS NULL))))
			), ResultCount AS(Select COUNT(ReceivingCustomerWorkId) AS totalItems FROM Result)
			Select * INTO #TempResult from  Result
			WHERE (
			(@GlobalFilter <>'' AND ((CustomerName like '%' +@GlobalFilter+'%' ) OR 
					(PartNumber like '%' +@GlobalFilter+'%') OR
					(PartDescription like '%' +@GlobalFilter+'%') OR
					(SerialNumber like '%' +@GlobalFilter+'%') OR
					(StocklineNumber like '%' +@GlobalFilter+'%') OR
					(ControlNumber like '%' +@GlobalFilter+'%') OR
					(IdNumber like '%' +@GlobalFilter+'%') OR
					(WorkOrderNum like '%' +@GlobalFilter+'%') OR
					(ReceivingNumber like '%' +@GlobalFilter+'%') OR
					(ReceivedBy like '%' +@GlobalFilter+'%') OR
					(LastMSLevel like '%' +@GlobalFilter+'%') OR
					(Status like '%'+@GlobalFilter+'%') OR
					(StageCode like '%'+@GlobalFilter+'%') OR
					(CreatedBy like '%' +@GlobalFilter+'%') OR
					(UpdatedBy like '%' +@GlobalFilter+'%') 
					))
					OR   
					(@GlobalFilter='' AND (ISNULL(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') and 
					(ISNULL(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') and
					(ISNULL(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') and
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') and
					(ISNULL(@StocklineNumber,'') ='' OR StocklineNumber like '%' + @StocklineNumber+'%') and
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber like '%' + @ControlNumber+'%') and
					(ISNULL(@IdNumber,'') ='' OR IdNumber like '%' + @IdNumber+'%') and
					(ISNULL(@WONumber,'') ='' OR WorkOrderNum like '%' + @WONumber+'%') and
					(ISNULL(@ReceivingNumber,'') ='' OR ReceivingNumber like '%' + @ReceivingNumber+'%') and
					(ISNULL(@ReceivedBy,'') ='' OR ReceivedBy like '%' + @ReceivedBy+'%') and

					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and
					(ISNULL(@StageCode,'') ='' OR StageCode like '%' + @StageCode+'%') and
					(ISNULL(@Status,'') ='' OR Status like '%' + @Status+'%') and

					(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') and
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') and
					(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate as Date)=CAST(@ReceivedDate AS DATE)) and
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate AS DATE)) and
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate AS DATE)))
					)

			Select @Count = COUNT(ReceivingCustomerWorkId) from #TempResult			

			SELECT *, @Count As NumberOfItems FROM #TempResult
			ORDER BY  
			
			CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='STOCKLINENUMBER')  THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNUMBER')  THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='IDNUMBER')  THEN IdNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGNUMBER')  THEN ReceivingNumber END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='STAGECODE')  THEN StageCode END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVEDBY')  THEN ReceivedBy END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVEDDATE')  THEN ReceivedDate END ASC,
            CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,

			CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='STOCKLINENUMBER')  THEN StockLineNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNUMBER')  THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='IDNUMBER')  THEN IdNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGNUMBER')  THEN ReceivingNumber END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='STAGECODE')  THEN StageCode END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVEDBY')  THEN ReceivedBy END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVEDDATE')  THEN ReceivedDate END DESC,
            CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC

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
              , @AdhocComments     VARCHAR(150)    = 'GetRecevingCustomerList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
							@Parameter2 = ' + ISNULL(@PageSize,'') + ', 
							@Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
							@Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
							@Parameter6 = ' + ISNULL(@GlobalFilter,'') + ', 
							@Parameter7 = ' + ISNULL(@CustomerName,'') + ', 
							@Parameter8 = ' + ISNULL(@PartNumber,'') + ', 
							@Parameter9 = ' + ISNULL(@PartDescription,'') + ', 
							@Parameter10 = ' + ISNULL(@SerialNumber,'') + ', 
							@Parameter11 = ' + ISNULL(@WONumber,'') + ', 
							@Parameter12 = ' + ISNULL(@ReceivingNumber,'') + ', 
							@Parameter13 = ' + ISNULL(@ReceivedDate,'') + ', 
							@Parameter14 = ' + ISNULL(@ReceivedBy,'') + ',
							@Parameter15 = ' + ISNULL(@CreatedDate,'') + ', 
							@Parameter16 = ' + ISNULL(@UpdatedDate,'') + ', 
							@Parameter17 = ' + ISNULL(@CreatedBy,'') + ', 
							@Parameter18 = ' + ISNULL(@UpdatedBy,'') + ', 
							@Parameter19 = ' + ISNULL(@IsDeleted,'') + ',
							@Parameter20 = ' + ISNULL(@LastMSLevel,'') + ', 
							@Parameter24 = ' + ISNULL(@StageCode,'') + ', 
							@Parameter25 = ' + ISNULL(@Status,'') + ', 
							@Parameter26 = ' + ISNULL(@WOFilter,'') + ', 
							@Parameter27 = ' + ISNULL(@EmployeeId,'') + ', 
							@Parameter28 = ' + ISNULL(@StocklineNumber,'') + ', 
							@Parameter28 = ' + ISNULL(@ControlNumber,'') + ', 
							@Parameter28 = ' + ISNULL(@IdNumber,'') + ', 
							@Parameter29 = ' + ISNULL(@MasterCompanyId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
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