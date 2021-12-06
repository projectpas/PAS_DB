/*************************************************************           
 ** File:   [WorkOrderROlist]           
 ** Author:   Subhahs Saliya
 ** Description: Get Search Data for Work Order Ro List    
 ** Purpose:         
 ** Date:   07-may-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/07/2020   Subhash Saliya Created
     
 EXECUTE [WorkOrderROlist] 1, 50, null, -1, 1, '', 'mpn', '','','','','','','','','all'
**************************************************************/ 

CREATE PROCEDURE [dbo].[WorkOrderROlist]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = '',
	@partNumber varchar(50) = null,
	@partDescription varchar(50)=null,
	@SerialNumber varchar(50)=null,
	@RepairOrderNumber varchar(50)=null,
	@QuantityOrdered varchar(50)=null,
    @ControlNumber varchar(50)=null,
    @ControllerId varchar(50)=null,
    @UnitCost varchar(50)=null,
    @ExtendedCost varchar(200)=null,
    @Currency varchar(50)=null,    
	@OpenDate datetime=null,
	@NeedByDate datetime=null,
	@VendorName varchar(200)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@MasterCompanyId varchar(200)=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON    	

	BEGIN TRY
	BEGIN TRANSACTION;

		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		DECLARE @WorkOrderStatusId int;		

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted is null
		Begin
			Set @IsDeleted=0
		End		


		IF (@GlobalFilter IS NULL OR @GlobalFilter = '')
		Begin
			Set @GlobalFilter= ''
		End 

		IF @SortColumn is null
		Begin
			Set @SortColumn=Upper('CreatedDate')
		End 
		Else
		Begin 
			Set @SortColumn=Upper(@SortColumn)
		End

		If @StatusID = 0
		Begin 
			Set @IsActive = 0
		End 
		else IF @StatusID = 1
		Begin 
			Set @IsActive = 1
		End 
		else IF @StatusID = 2
		Begin 
			Set @IsActive=null
		End 

			;WITH Result AS(
					SELECT	
						          ro.RepairOrderId,
                                  RepairOrderPartRecordId = rop.RepairOrderPartRecordId,
                                  PartNumber =  im.PartNumber,
                                  PartDescription =im.PartDescription,
                                  SerialNumber =sl.SerialNumber,
                                  ro.RepairOrderNumber,
                                  QuantityOrdered = rop.QuantityOrdered,
                                  ControlNumber =sl.ControlNumber,
                                  ControllerId =sl.IdNumber,
                                  UnitCost = rop.UnitCost,
                                  ExtendedCost = rop.ExtendedCost,
                                  Currency = cur.DisplayName,
                                  v.VendorName,
                                  Status = 'Open',
                                  ro.OpenDate,
                                  ro.NeedByDate
					FROM RepairOrder ro WITH(NOLOCK)
						JOIN dbo.RepairOrderPart rop WITH(NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId
						JOIN dbo.ItemMaster im WITH(NOLOCK) ON rop.ItemMasterId = im.ItemMasterId
						JOIN dbo.StockLine sl WITH(NOLOCK) ON rop.StockLineId = sl.StockLineId
						JOIN dbo.Vendor v WITH(NOLOCK) ON ro.VendorId = v.VendorId
						JOIN dbo.Currency cur WITH(NOLOCK) ON rop.ReportCurrencyId = cur.CurrencyId
					WHERE ((ro.MasterCompanyId = @MasterCompanyId) AND (ro.IsDeleted = @IsDeleted) AND (@IsActive is null or ro.IsActive = @IsActive))
						), ResultCount AS(Select COUNT(RepairOrderId) AS totalItems FROM Result)
						Select * INTO #TempResult from  Result
						WHERE (
						(@GlobalFilter <>'' AND (
						(PartNumber like '%' +@GlobalFilter+'%') OR
						(PartDescription like '%' +@GlobalFilter+'%') OR
						(SerialNumber like '%' +@GlobalFilter+'%') OR
						(RepairOrderNumber like '%' +@GlobalFilter+'%') OR
						(QuantityOrdered like '%' +@GlobalFilter+'%') OR		
						(ControlNumber like '%' +@GlobalFilter+'%' ) OR 
						(ControllerId like '%' +@GlobalFilter+'%') OR
						(UnitCost like '%' +@GlobalFilter+'%') OR
						(ExtendedCost like '%'+@GlobalFilter+'%') OR
						(Currency like '%'+@GlobalFilter+'%')
						--(CreatedBy like '%' +@GlobalFilter+'%') OR
						--(UpdatedBy like '%' +@GlobalFilter+'%') 
						))
						OR   
						(@GlobalFilter='' AND (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
						(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
						(IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
						(IsNull(@RepairOrderNumber,'') ='' OR RepairOrderNumber like '%' + @RepairOrderNumber+'%') AND
						(IsNull(@QuantityOrdered,'') ='' OR QuantityOrdered like '%' + @QuantityOrdered+'%') AND
						(IsNull(@ControlNumber,'') ='' OR ControlNumber like '%' + @ControlNumber+'%') AND
						(IsNull(@ControllerId,'') ='' OR ControllerId like '%' + @ControllerId+'%') AND
						(IsNull(@UnitCost,'') ='' OR UnitCost like '%' + @UnitCost+'%') AND
						(IsNull(@ExtendedCost,'') ='' OR ExtendedCost like '%' + @ExtendedCost+'%') AND
						(IsNull(@Currency,'') ='' OR Currency like '%' + @Currency+'%') AND
						(IsNull(@VendorName,'') ='' OR VendorName like '%' + @VendorName+'%') AND
						--(IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') AND
						--(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
						--(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
						(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND
						(IsNull(@NeedByDate,'') ='' OR Cast(NeedByDate as Date)=Cast(@NeedByDate as date))
						--(IsNull(@PromiseDate,'') ='' OR Cast(PromisedDate as Date)=Cast(@PromiseDate as date)) AND
						--(IsNull(@EstShipDate,'') ='' OR Cast(EstimatedShipDate as Date)=Cast(@EstShipDate as date)) AND
						--(IsNull(@ShipDate,'') ='' OR Cast(EstimatedCompletionDate as Date)=Cast(@ShipDate as date)) AND					
						--(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND
						--(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date))
						))

						Select @Count = COUNT(RepairOrderId) from #TempResult			

						SELECT *, @Count As NumberOfItems FROM #TempResult
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER ')  THEN PartNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='REPAIRORDERNUMBER')  THEN RepairOrderNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUANTITYORDERED')  THEN QuantityOrdered END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNUMBER')  THEN ControlNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLLERID')  THEN ControllerId END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UNITCOST')  THEN UnitCost END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='EXTENDEDCOST')  THEN ExtendedCost END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CURRENCY')  THEN Currency END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='NEEDBYDATE')  THEN NeedByDate END ASC,


						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER ')  THEN PartNumber END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='REPAIRORDERNUMBER')  THEN RepairOrderNumber END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUANTITYORDERED')  THEN QuantityOrdered END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNUMBER')  THEN ControlNumber END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLLERID')  THEN ControllerId END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UNITCOST')  THEN UnitCost END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='EXTENDEDCOST')  THEN ExtendedCost END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CURRENCY')  THEN Currency END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='NEEDBYDATE')  THEN NeedByDate END desc

						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
	COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'WorkOrderROlist' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StatusID, '') + ''
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