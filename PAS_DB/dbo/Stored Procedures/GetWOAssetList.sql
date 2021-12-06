
/*************************************************************           
 ** File:   [GetWOAssetList]           
 ** Author:   Hemant Saliya
 ** Description: Get Search Data for Customer List    
 ** Purpose:         
 ** Date:   14-Dec-2020        
          
 ** PARAMETERS:  @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/14/2020   Hemant Saliya Created
	2    12/17/2020   Hemant Saliya Updated Like for General Filter
	3    07/24/2021   Hemant Saliya Add Task In WO Asset
     
 EXECUTE [GetWOAssetList] 10, 1, null, -1, '', 162, '','','',null,null,null,null,null,null,0,1
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWOAssetList]
	@PageSize int,
	@PageNumber int,
	@SortColumn varchar(50) = null,
	@SortOrder int,	
	@GlobalFilter varchar(50) = null,
	@WorkFlowWorkOrderId Bigint = null,
	@Name varchar(50) = null,	
	@AssetId varchar(50) = null,
	@Description varchar(50) = null,
	@AssetTypeName varchar(50) = null,
    @Quantity int = null,    
    @CheckInDate datetime = null,
    @CheckOutDate  datetime = null,
	@CheckInBy  varchar(50) = null,
	@CheckOutBy  varchar(50) = null,
    @IsDeleted bit= null,
	@MasterCompanyId bigint = NULL,
	@Status  varchar(50) = null,
	@TaskName  varchar(50) = null,
	@IsFromWorkFlowNew  varchar(50) = ''
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
    BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom int;
				DECLARE @IsActive bit=1
				DECLARE @Count Int;
				--DECLARE	@IsFromWorkFlowNew  varchar(50) = null

				--if(@IsFromWorkFlow = 0)
				--begin

				--set @IsFromWorkFlowNew ='No'
				--end
				--else if(@IsFromWorkFlow = 1)
				--begin
				--set @IsFromWorkFlowNew ='Yes'
				--end
				--else
				--begin
				--set @IsFromWorkFlowNew =''
				--end

				SET @RecordFrom = (@PageNumber-1)*@PageSize;
				IF @IsDeleted is null
				BEGIN
					SET @IsDeleted=0
				END
		
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('CreatedDate')
				END 
				ELSE
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END
		
				;With Result AS(
					SELECT	
							WOA.AssetRecordId,
							WOA.WorkOrderId,
							WOA.WorkFlowWorkOrderId AS WorkOrderWfId,
							AI.InventoryNumber AS InventoryNumber,
							WOA.WorkOrderAssetId,
							A.AssetId,
							A.Description,
							A.Name,
							T.Description AS TaskName,
							T.TaskId,
							AAT.AssetAttributeTypeName AS AssetTypeName,
							AAT.TangibleClassId,
							WOA.Quantity,
							(CIE.FirstName + ' ' + CIE.LastName) AS CheckInEmp,
							(CIB.FirstName + ' ' + CIB.LastName) AS CheckInBy,
							(COE.FirstName + ' ' + COE.LastName) AS CheckOutEmp,
							(COB.FirstName + ' ' + COB.LastName) AS CheckOutBy,
							WOA.IsActive,
							WOA.IsDeleted,
							WOA.CreatedDate,
							WOA.CreatedBy,
							WOA.UpdatedDate,
							WOA.UpdatedBy,
							WOA.MasterCompanyId,
							COCI.CheckInDate,
							COCI.CheckOutDate,
							WOA.IsFromWorkFlow,
							case when isnull(WOA.IsFromWorkFlow,0) =0 then 'No' else 'Yes' end IsFromWorkFlowNew,
							CASE WHEN  ISNULL(COCI.CheckOutDate,'') !='' THEN 'Checked Out of WO' WHEN isnull(COCI.CheckInDate,'') !='' THEN 'Checked In To WO'  ELSE ''  END  AS Status
						FROM dbo.WorkOrderAssets WOA WITH(NOLOCK)
							JOIN dbo.Asset A WITH(NOLOCK) on WOA.AssetRecordId = A.AssetRecordId
							JOIN dbo.Task T WITH(NOLOCK) on T.TaskId = WOA.TaskId
							JOIN dbo.AssetAttributeType AAT WITH(NOLOCK) on A.TangibleClassId = AAT.TangibleClassId
							LEFT JOIN dbo.CheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) ON WOA.WorkOrderAssetId = COCI.WorkOrderAssetId AND COCI.IsQtyCheckOut = 1
							LEFT JOIN dbo.AssetInventory AI WITH(NOLOCK) ON COCI.AssetInventoryId =  AI.AssetInventoryId
							--LEFT JOIN dbo.AssetInventoryStatus AIS ON AIS.AssetInventoryStatusId =  AI.InventoryStatusId
							LEFT JOIN dbo.Employee CIE WITH(NOLOCK) ON COCI.CheckInEmpId = CIE.EmployeeId
							LEFT JOIN dbo.Employee CIB WITH(NOLOCK) ON COCI.CheckInById = CIB.EmployeeId
							LEFT JOIN dbo.Employee COE WITH(NOLOCK) ON COCI.CheckOutEmpId = COE.EmployeeId
							LEFT JOIN dbo.Employee COB WITH(NOLOCK) ON COCI.CheckOutById = COB.EmployeeId
						WHERE WOA.IsDeleted = @IsDeleted AND WOA.MasterCompanyId = @MasterCompanyId AND WOA.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					), ResultCount AS(SELECT COUNT(AssetRecordId) AS totalItems FROM Result)
					SELECT * INTO #TempResult from  Result
					WHERE (
					(@GlobalFilter <>'' AND ((Name like '%' +@GlobalFilter+'%' ) OR (AssetId like '%' +@GlobalFilter+'%') OR
							(Description like '%' +@GlobalFilter+'%') OR
							(AssetTypeName like '%' +@GlobalFilter+'%') OR
							(CAST(Quantity AS NVARCHAR(10)) like '%' +@GlobalFilter+'%') OR					
							(CheckOutBy like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(TaskName like '%' +@GlobalFilter+'%') OR
							(IsFromWorkFlow like '%' +@GlobalFilter+'%') OR
							(CheckInBy like '%' +@GlobalFilter+'%')))
							OR   
							(@GlobalFilter='' AND (ISNULL(@Name,'') ='' OR Name like '%' + @Name+'%') AND 
							(ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
							(ISNULL(@Description,'') ='' OR Description like '%' + @Description+'%') AND
							(ISNULL(@AssetTypeName,'') ='' OR AssetTypeName like '%' + @AssetTypeName+'%') AND
							(ISNULL(@Quantity,'') ='' OR Quantity = @Quantity) AND	
							(ISNULL(@CheckInBy,'') ='' OR CheckInBy like '%' + @CheckInBy+'%') AND
							(ISNULL(@Status,'') ='' OR Status like '%' + @Status+'%') AND
							(ISNULL(@TaskName,'') ='' OR TaskName like '%' + @TaskName+'%') AND
							(ISNULL(@CheckOutBy,'') ='' OR CheckOutBy like '%' + @CheckOutBy+'%') AND
							(ISNULL(@IsFromWorkFlowNew,'') ='' OR IsFromWorkFlowNew like '%' + @IsFromWorkFlowNew+'%' ) AND
							(ISNULL(@CheckInDate,'') ='' OR CAST(CheckInDate AS DATE)=CAST(@CheckInDate AS DATE)) AND
							(ISNULL(@CheckOutDate,'') ='' OR CAST(CheckOutDate AS DATE)=CAST(@CheckOutDate AS DATE))))

				SELECT @Count = COUNT(AssetRecordId) FROM #TempResult			

				SELECT *, @Count As NumberOfItems FROM #TempResult
					ORDER BY  			
					CASE WHEN (@SortOrder=1 and @SortColumn='NAME')  THEN Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='DESCRIPTION')  THEN Description END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPENAME')  THEN AssetTypeName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QUANTITY')  THEN Quantity END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CHECKINBY')  THEN CheckInBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CHECKOUTBY')  THEN CheckOutBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CHECKINDATE')  THEN CheckInDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CHECKOUTDATE')  THEN CheckOutDate END ASC,					
					CASE WHEN (@SortOrder=1 and @SortColumn='TASKNAME')  THEN TaskName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ISFROMWORKFLOW')  THEN IsFromWorkFlow END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='NAME')  THEN Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='DESCRIPTION')  THEN Description END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPENAME')  THEN AssetTypeName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QUANTITY')  THEN Quantity END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CHECKINBY')  THEN CheckInBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CHECKOUTBY')  THEN CheckOutBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CHECKINDATE')  THEN CheckInDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CHECKOUTDATE')  THEN CheckOutDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='TASKNAME')  THEN TaskName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ISFROMWORKFLOW')  THEN IsFromWorkFlow END DESC
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
              , @AdhocComments     VARCHAR(150)    = 'GetWOAssetList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageSize, '') + ''',
													   @Parameter2 = ' + ISNULL(@PageNumber ,'') +'''
													   @Parameter3 = ' + ISNULL(@SortColumn ,'') +'''
													   @Parameter4 = ' + ISNULL(@GlobalFilter ,'') +'''
													   @Parameter5 = ' + ISNULL(@WorkFlowWorkOrderId ,'') +'''
													   @Parameter6 = ' + ISNULL(@Name ,'') +'''
													   @Parameter7 = ' + ISNULL(@AssetId ,'') +'''
													   @Parameter8 = ' + ISNULL(@Description ,'') +'''
													   @Parameter9 = ' + ISNULL(@AssetTypeName ,'') +'''
													   @Parameter10 = ' + ISNULL(@Quantity ,'') +'''
													   @Parameter11 = ' + ISNULL(CAST(@CheckInDate AS varchar(20)) ,'') +'''
													   @Parameter12 = ' + ISNULL(CAST(@CheckOutDate AS varchar(20)) ,'') +'''
													   @Parameter13 = ' + ISNULL(@CheckInBy ,'') +'''
													   @Parameter14 = ' + ISNULL(@CheckOutBy ,'') +'''
													   @Parameter15 = ' + ISNULL(CAST(@IsDeleted AS varchar(10)) ,'') +'''
													   @Parameter16 = ' + ISNULL(@MasterCompanyId ,'') +'''
													   @Parameter17 = ' + ISNULL(@TaskName ,'') +'''
													   @Parameter18 = ' + ISNULL(CAST(@Status AS varchar(20)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END