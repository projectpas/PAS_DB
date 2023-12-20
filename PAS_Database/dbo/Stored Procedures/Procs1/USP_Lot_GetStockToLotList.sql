/*************************************************************           
 ** File:   [USP_Lot_GetStockToLotList]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to Get Stock To Lot Listing 
 ** Date:   05/04/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    05/04/2023   Amit Ghediya     Created
	2    21/11/2023   Amit Ghediya     Updated for get lotout unitcost & ext Cost amount for trans out.
**************************************************************
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_Lot_GetStockToLotList] 
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@LotId bigint = NULL,
	@PN varchar(50)=NULL,
	@PNDescription varchar(200) = NULL,
	@ManufacturerName varchar(200) = NULL,
	@GlobalFilter varchar(50) = '',	
	@SerialNum varchar(50) = NULL,
	@Cond varchar(200) = NULL,
	@PONum varchar(100) = NULL,
	@UOM varchar(200) = NULL,
	@ItemClassification varchar(200) = NULL,
	@ItemGroup varchar(100) = NULL,
	@StkLineNum varchar(200) = NULL,
	@QtyAdded decimal(18,2) = NULL,
	@TransInUnitCost decimal(18,2) = NULL,
	@CO varchar(200) = NULL,
	@BU varchar(200) = NULL,
	@Div varchar(200) = NULL,
	@Dept varchar(200) = NULL,
	@Memo varchar(200) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@MasterCompanyId bigint = NULL,
	@IsInOut BIT = NULL,
	@AddedDate datetime = NULL,
	@Quantity int = NULL,
	@CntrlNumber varchar(200) = NULL,
	@UnitCost decimal(18,2) = NULL,
	@ExtUnitCost decimal(18,2) = NULL,
	@TraceableToName varchar(200) = NULL,
	@TaggedByName varchar(200) = NULL,
	@TagDate datetime = NULL,
	@EmployeeId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @Count Int;
		DECLARE @RecordFrom int;
		DECLARE @MSModuelId int,@LotMSModuelId int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		SET @MSModuelId = 2;   -- For Stockline
		SET @LotMSModuelId = 42 -- For LOT
		--Select  @MSModuelId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'StockLine';

		IF(@IsInOut = 1) --From IN
		BEGIN
			;WITH Result AS (	
				SELECT 
					ind.LotTransInOutId,
					stl.StockLineId,				
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
					UPPER((ISNULL(im.PartNumber,''))) 'PN',
					UPPER((ISNULL(im.PartDescription,''))) 'PNDescription',
					UPPER((ISNULL(im.ManufacturerName,''))) 'ManufacturerName',
					CASE WHEN stl.isSerialized = 1 THEN UPPER(ISNULL(stl.SerialNumber,'')) ELSE UPPER(ISNULL(stl.SerialNumber,'')) END AS 'SerialNum',
					UPPER(ISNULL(con.Description,'')) 'Cond', 	
					UPPER((ISNULL(stl.StockLineNumber,''))) 'StocklineNumber', 
					CAST(ind.QtyToTransIn AS varchar) 'Quantity',
					CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
					CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
					CAST(stl.UnitCost AS varchar) 'UnitCost',		
					CAST((ISNULL(stl.UnitCost,0) * ISNULL(ind.QtyToTransIn,0)) AS varchar) 'ExtUnitCost',
					UPPER((ISNULL(po.PurchaseOrderNumber,''))) 'PONum',
					UPPER((ISNULL(ro.RepairOrderNumber,''))) 'RepairOrderNumber',		
					vp.VendorName AS Vendor,						  
					stl.MasterCompanyId,	
					stl.CreatedDate,
					0 AS Isselected,
					0 AS IsCustomerStock,
					UPPER(MSD.Level1Name) AS cO,
					UPPER(MSD.Level2Name) AS bU,
					UPPER(MSD.Level3Name) AS div,
					UPPER(MSD.Level4Name) AS dept,
					UPPER(ind.TransInMemo) AS memo
					,UPPER(MSD.LastMSLevel)	LastMSLevel
					,UPPER(MSD.AllMSlevels) AllMSlevels
					,UPPER(stl.UnitOfMeasure) AS Uom
				    ,UPPER(stl.ControlNumber) AS CntrlNumber
					,ind.CreatedDate AS AddedDate
					,stl.TraceableToName
					,stl.TaggedByName
					,stl.TagDate
				FROM [dbo].LotTransInOutDetails ind WITH (NOLOCK)
				INNER JOIN DBO.Lot lt WITH(NOLOCK) on ind.LotId = lt.LotId
				INNER JOIN [dbo].[StockLine] stl WITH (NOLOCK) ON ind.StockLineId = stl.StockLineId
				INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
				INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId    
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId 
				LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId --and po.PurchaseOrderId != lt.InitialPOId
				LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [dbo].[Vendor] vp WITH (NOLOCK) ON stl.VendorId = vp.VendorId
				LEFT JOIN [dbo].[Condition] con WITH(NOLOCK) ON stl.ConditionId = con.ConditionId
				WHERE ISNULL(ind.QtyToTransIn,0) != 0 AND ind.LotId = @LotId AND ISNULL(po.PurchaseOrderId,1) != ISNULL(lt.InitialPOId,0) AND (SELECT ISNULL(IsFromPreCostStk,0) FROM DBO.LotCalculationDetails LC WITH(NOLOCK) WHERE ind.LotTransInOutId = LC.LotTransInOutId AND REPLACE([Type],' ','') = REPLACE('Trans In(Lot)',' ','') ) = 0
		  		) ,FinalResult AS (
					SELECT * FROM Result
			WHERE (
					(@GlobalFilter <>'' AND ((PN like '%' +@GlobalFilter+'%') OR 
							(PNDescription like '%' +@GlobalFilter+'%') OR
							(ManufacturerName like '%' +@GlobalFilter+'%') OR
							(SerialNum like '%' +@GlobalFilter+'%') OR
							(Cond like '%' +@GlobalFilter+'%') OR
							(CAST(Quantity AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(PONum like '%'+@GlobalFilter+'%') OR
						    (UOM like '%'+@GlobalFilter+'%') OR  
							(CAST(QuantityOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR --
							(CAST(QuantityAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR  --
							(CAST(UnitCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(CAST(ExtUnitCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(RepairOrderNumber like '%'+@GlobalFilter+'%') OR  --
							(Vendor like '%'+@GlobalFilter+'%') OR  --
							(LastMSLevel like '%'+@GlobalFilter+'%') OR  --
							(CntrlNumber like '%'+@GlobalFilter+'%') OR
							(AddedDate like '%'+@GlobalFilter+'%') OR
							(TraceableToName like '%'+@GlobalFilter+'%') OR
							(TaggedByName like '%'+@GlobalFilter+'%') OR
							(TagDate like '%'+@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND 
							(IsNull(@PN,'') ='' OR PN like  '%'+@PN+'%') AND
							(IsNull(@PNDescription,'') ='' OR PNDescription like  '%'+@PNDescription+'%') AND
							(IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%'+@ManufacturerName+'%') AND
							(IsNull(@SerialNum,'') ='' OR SerialNum like '%'+ @SerialNum+'%') AND
							(ISNULL(@AddedDate,'') ='' OR CAST(AddedDate AS Date) = CAST(@AddedDate AS date)) AND
							(IsNull(@Quantity, 0) = 0 OR CAST(Quantity as VARCHAR(10)) like @Quantity) AND
							(IsNull(@PONum,'') ='' OR PONum like '%'+ @PONum+'%') AND
							(IsNull(@UOM,'') ='' OR Uom like '%'+ @UOM+'%') AND
							(IsNull(@StkLineNum,'') ='' OR StocklineNumber like '%'+ @StkLineNum+'%') and
							(IsNull(@CntrlNumber,'') ='' OR CntrlNumber like '%'+ @CntrlNumber+'%') and
							(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
							(ISNULL(@ExtUnitCost, 0) = 0 OR CAST(ExtUnitCost as VARCHAR(10)) LIKE @ExtUnitCost) AND
							(IsNull(@TraceableToName,'') ='' OR TraceableToName like '%'+ @TraceableToName+'%') and
							(IsNull(@TaggedByName,'') ='' OR TaggedByName like '%'+ @TaggedByName+'%') and
							(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
							(IsNull(@Cond,'') ='' OR Cond like '%'+@Cond+'%')
							))
							)
								,
							ResultCount AS (Select COUNT(LotTransInOutId) AS NumberOfItems FROM FinalResult)
							SELECT * FROM FinalResult, ResultCount

							ORDER BY  
							CASE WHEN (@SortOrder=1  AND @SortColumn='PN')  THEN PN END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='PN')  THEN PN END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='PNDescription')  THEN PNDescription END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='PNDescription')  THEN PNDescription END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,			
							CASE WHEN (@SortOrder=1  AND @SortColumn='Cond')  THEN Cond END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='Cond')  THEN Cond END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='Quantity')  THEN Quantity END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='Quantity')  THEN Quantity END DESC,           
							CASE WHEN (@SortOrder=1  AND @SortColumn='PONum')  THEN PONum END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='PONum')  THEN PONum END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='UOM')  THEN UOM END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='UOM')  THEN UOM END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='ExtUnitCost')  THEN ExtUnitCost END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='ExtUnitCost')  THEN ExtUnitCost END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,			
							CASE WHEN (@SortOrder=1  AND @SortColumn='Vendor')  THEN Vendor END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='Vendor')  THEN Vendor END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,           
							CASE WHEN (@SortOrder=1  AND @SortColumn='CntrlNumber')  THEN CntrlNumber END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='CntrlNumber')  THEN CntrlNumber END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='AddedDate')  THEN AddedDate END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='AddedDate')  THEN AddedDate END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,							
							CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC
					
						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			;WITH Result AS (	
				SELECT 
					ind.LotTransInOutId,
					stl.StockLineId,				
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
					UPPER((ISNULL(im.PartNumber,''))) 'PN',
					UPPER((ISNULL(im.PartDescription,''))) 'PNDescription',
					UPPER((ISNULL(im.ManufacturerName,''))) 'ManufacturerName',
					CASE WHEN stl.isSerialized = 1 THEN UPPER(ISNULL(stl.SerialNumber,'')) ELSE UPPER(ISNULL(stl.SerialNumber,'')) END AS 'SerialNum',
					UPPER(ISNULL(con.Description,'')) 'Cond', 	 	
					UPPER((ISNULL(stl.StockLineNumber,''))) 'StocklineNumber', 
					CAST(ind.QtyToTransOut AS varchar) 'Quantity',
					CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
					CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
					CAST(ind.UnitCost AS varchar) 'UnitCost',		
					CAST((ISNULL(ind.UnitCost,0) * ISNULL(ind.QtyToTransOut,0)) AS varchar) 'ExtUnitCost',
					UPPER((ISNULL(po.PurchaseOrderNumber,''))) 'PONum',
					UPPER((ISNULL(ro.RepairOrderNumber,''))) 'RepairOrderNumber',		
					vp.VendorName AS Vendor,						  
					stl.MasterCompanyId,	
					stl.CreatedDate,
					0 AS Isselected,
					0 AS IsCustomerStock,
					UPPER(MSD.Level1Name) AS cO,
					UPPER(MSD.Level2Name) AS bU,
					UPPER(MSD.Level3Name) AS div,
					UPPER(MSD.Level4Name) AS dept,
					UPPER(ind.TransOutMemo) AS memo
					,UPPER(MSD.LastMSLevel)	LastMSLevel
					,UPPER(MSD.AllMSlevels) AllMSlevels
					,UPPER(stl.UnitOfMeasure) AS Uom
				    ,UPPER(stl.ControlNumber) AS CntrlNumber
					,ind.CreatedDate AS AddedDate
					,stl.TraceableToName
					,stl.TaggedByName
					,stl.TagDate
				FROM DBO.LotTransInOutDetails ind WITH (NOLOCK)
				--INNER JOIN DBO.LotCalculationDetails LC WITH(NOLOCK) ON ind.LotTransInOutId = LC.LotTransInOutId
				INNER JOIN [dbo].[StockLine] stl WITH (NOLOCK) ON ind.StockLineId = stl.StockLineId
				INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
				INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId    
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [dbo].[Vendor] vp WITH (NOLOCK) ON stl.VendorId = vp.VendorId
				LEFT JOIN [dbo].[Condition] con WITH(NOLOCK) ON stl.ConditionId = con.ConditionId
				WHERE ISNULL(ind.QtyToTransOut,0) != 0 AND ind.LotId = @LotId AND (SELECT ISNULL(IsFromPreCostStk,0) FROM DBO.LotCalculationDetails LC WITH(NOLOCK) WHERE ind.LotTransInOutId = LC.LotTransInOutId AND REPLACE([Type],' ','') = REPLACE('Trans Out(Lot)',' ','') ) = 0 
		  		) ,FinalResult AS (
					SELECT * FROM Result
			WHERE (
					(@GlobalFilter <>'' AND ((PN like '%' +@GlobalFilter+'%') OR 
							(PNDescription like '%' +@GlobalFilter+'%') OR
							(ManufacturerName like '%' +@GlobalFilter+'%') OR
							(SerialNum like '%' +@GlobalFilter+'%') OR
							(Cond like '%' +@GlobalFilter+'%') OR
							(CAST(Quantity AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(PONum like '%'+@GlobalFilter+'%') OR
						    (UOM like '%'+@GlobalFilter+'%') OR  
							(CAST(QuantityOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR --
							(CAST(QuantityAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR  --
							(CAST(UnitCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(CAST(ExtUnitCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(RepairOrderNumber like '%'+@GlobalFilter+'%') OR  --
							(Vendor like '%'+@GlobalFilter+'%') OR  --
							(LastMSLevel like '%'+@GlobalFilter+'%') OR  --
							(CntrlNumber like '%'+@GlobalFilter+'%') OR
							(AddedDate like '%'+@GlobalFilter+'%') OR
							(TraceableToName like '%'+@GlobalFilter+'%') OR
							(TaggedByName like '%'+@GlobalFilter+'%') OR
							(TagDate like '%'+@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND 
							(IsNull(@PN,'') ='' OR PN like  '%'+@PN+'%') AND
							(IsNull(@PNDescription,'') ='' OR PNDescription like  '%'+@PNDescription+'%') AND
							(IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%'+@ManufacturerName+'%') AND
							(IsNull(@SerialNum,'') ='' OR SerialNum like '%'+ @SerialNum+'%') AND
							(ISNULL(@AddedDate,'') ='' OR CAST(AddedDate AS Date) = CAST(@AddedDate AS date)) AND
							(IsNull(@Quantity, 0) = 0 OR CAST(Quantity as VARCHAR(10)) like @Quantity) AND
							(IsNull(@PONum,'') ='' OR PONum like '%'+ @PONum+'%') AND
							(IsNull(@UOM,'') ='' OR Uom like '%'+ @UOM+'%') AND
							(IsNull(@StkLineNum,'') ='' OR StocklineNumber like '%'+ @StkLineNum+'%') and
							(IsNull(@CntrlNumber,'') ='' OR CntrlNumber like '%'+ @CntrlNumber+'%') and
							(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
						    (ISNULL(@ExtUnitCost, 0) = 0 OR CAST(ExtUnitCost as VARCHAR(10)) LIKE @ExtUnitCost) AND
							(IsNull(@TraceableToName,'') ='' OR TraceableToName like '%'+ @TraceableToName+'%') and
							(IsNull(@TaggedByName,'') ='' OR TaggedByName like '%'+ @TaggedByName+'%') and
							(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
							(IsNull(@Cond,'') ='' OR Cond like '%'+@Cond+'%')
							)))
								,
							ResultCount AS (Select COUNT(LotTransInOutId) AS NumberOfItems FROM FinalResult)
							SELECT * FROM FinalResult, ResultCount

						ORDER BY  
						CASE WHEN (@SortOrder=1  AND @SortColumn='PN')  THEN PN END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='PN')  THEN PN END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='PNDescription')  THEN PNDescription END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='PNDescription')  THEN PNDescription END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,			
							CASE WHEN (@SortOrder=1  AND @SortColumn='Cond')  THEN Cond END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='Cond')  THEN Cond END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='Quantity')  THEN Quantity END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='Quantity')  THEN Quantity END DESC,           
							CASE WHEN (@SortOrder=1  AND @SortColumn='PONum')  THEN PONum END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='PONum')  THEN PONum END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='UOM')  THEN UOM END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='UOM')  THEN UOM END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='ExtUnitCost')  THEN ExtUnitCost END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='ExtUnitCost')  THEN ExtUnitCost END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,			
							CASE WHEN (@SortOrder=1  AND @SortColumn='Vendor')  THEN Vendor END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='Vendor')  THEN Vendor END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,           
							CASE WHEN (@SortOrder=1  AND @SortColumn='CntrlNumber')  THEN CntrlNumber END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='CntrlNumber')  THEN CntrlNumber END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='AddedDate')  THEN AddedDate END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='AddedDate')  THEN AddedDate END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,
							CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,
							CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC
					
						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
		END
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetStockToLotList]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END