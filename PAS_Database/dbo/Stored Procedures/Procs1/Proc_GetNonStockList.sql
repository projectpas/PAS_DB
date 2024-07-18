/*************************************************************           
 ** File:   [Proc_GetNonStockList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used GET lIST Non Stockline Details.    
 ** Purpose:         
 ** Date:    02/04/2020       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/04/2020   Subhash Saliya Created
	2   17 July 2024   Shrey Chandegara       Modified( use this function @CurrntEmpTimeZoneDesc for date issue.)

     
--  EXEC [Proc_GetNonStockList] 1
**************************************************************/

CREATE PROCEDURE [dbo].[Proc_GetNonStockList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@stockTypeId int = NULL,
@NonStockInventoryNumber varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@ControlNumber varchar(50) = NULL,
@UnitOfMeasure varchar(50) = NULL,
@SerialNumber  varchar(50) = NULL,
@GLAccount varchar(50) = NULL,
@ReceiverNumber varchar(50) = NULL,
@Condition varchar(50) = NULL,
@Quantity varchar(50) = NULL,
@QuantityOnHand varchar(50) = NULL,
@QuantityRejected varchar(50) = NULL,
@LastMSLevel varchar(50) = NULL,
@Currency varchar(50) = NULL,
@IdNumber varchar(50) = NULL,
@ReceivedDate datetime = NULL,
@OrderDate datetime = NULL,
@EntryDate datetime = NULL,
@MfgExpirationDate datetime = NULL,
@Manufacturer varchar(50) = NULL,
@UnitCost varchar(50) = NULL,
@ExtendedCost  varchar(50) = NULL,
@Acquired varchar(50) = NULL,
@IsHazardousMaterial varchar(50) = NULL,
@NonStockClassification  varchar(50) = NULL,
@ShippingVia varchar(50) = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@ShippingAccount varchar(50) = NULL,
@MasterCompanyId BIGINT = NULL,
@ShippingReference varchar(50) = NULL,
@MasterPartId BIGINT = NULL,
@StockLineIds varchar(1000) = NULL,
@EmployeeId BIGINT = NULL,
@Memo varchar(50) = NULL,
@VendorName varchar(50) = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @MSModuelId INT = 11; -- For Non Stockline
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	    SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		SET @RecordFrom = (@PageNumber-1)*@PageSize;	
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END	

		IF(@stockTypeId = 0)
		BEGIN
			 SET @stockTypeId = NULL;
		END

		IF @MasterPartId = 0
		BEGIN
			SET @MasterPartId = NULL
		END 

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF @stockTypeId = 1 -- Qty OH > 0
				BEGIN
					;WITH Result AS(
					SELECT DISTINCT  stl.NonStockInventoryId as NonStockInventoryId,				
						   (ISNULL(im.MasterPartId,0)) 'ItemMasterId',
						   (ISNULL(im.MasterPartId,0)) 'MasterPartId',
						   (ISNULL(im.PartNumber,'')) 'PartNumber',
						   (ISNULL(im.PartDescription,'')) 'PartDescription',
						   (ISNULL(stl.Manufacturer,'')) 'Manufacturer',  
						   (ISNULL(stl.PurchaseOrderNumber,'')) 'PurchaseOrderNumber', 
						   (ISNULL(stl.PurchaseOrderId,0)) 'PurchaseOrderId',
						   (ISNULL(stl.PurchaseOrderPartRecordId,0)) 'PurchaseOrderPartRecordId',
						   (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',						   			   
						   (ISNULL(stl.SerialNumber,'')) 'SerialNumber',
						   (ISNULL(stl.NonStockInventoryNumber,'')) 'NonStockInventoryNumber', 						   
						   (ISNULL(stl.Condition,'')) AS  'Condition', 					   
						   (ISNULL(stl.ReceivedDate,'')) AS  'ReceivedDate',
						   (ISNULL(stl.OrderDate,''))AS  'OrderDate',					  
						   (ISNULL(stl.EntryDate,'')) AS 'EntryDate',
						   (ISNULL(stl.MfgExpirationDate,'')) AS 'MfgExpirationDate',
						   (ISNULL(stl.GLAccount,'')) 'GLAccount',
						   (ISNULL(stl.UnitCost,0))as  'UnitCost',	
						   (ISNULL(stl.ExtendedCost,0)) as 'ExtendedCost',					   
						   CASE WHEN stl.Acquired = 1 THEN 'Yes' ELSE 'No' END AS Acquired,
						   (ISNULL(stl.NonStockClassification,'')) as 'NonStockClassification',	
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',						   
						   CAST(stl.QuantityRejected AS varchar) 'QuantityRejected',						   
						   CAST(stl.Quantity AS varchar) 'Quantity',			
						   stl.IsHazardousMaterial as 'IsHazardousMaterial',	
						   stl.ControlNumber,
						   stl.IdNumber,
						   stl.Quantity  as Quantitynew,
						   stl.QuantityRejected  as QuantityRejectednew,
						   stl.QuantityOnHand  as QuantityOnHandnew,
						   stl.IsActive,                     
						   stl.CreatedDate,
						   stl.CreatedBy,
						   stl.VendorName,
						   stl.Requisitioner,
						   stl.ReceiverNumber,
						   stl.UpdatedDate,					   
						   stl.UpdatedBy,
						   MSD.LastMSLevel,
						   MSD.AllMSlevels	
					 FROM  NonStockInventory stl WITH (NOLOCK)
							INNER JOIN ItemMasterNonStock im WITH (NOLOCK) ON stl.MasterPartId = im.MasterPartId 
							INNER JOIN  dbo.NonStocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.NonStockInventoryId AND MSD.ModuleID = @MSModuelId
		 		  WHERE ((stl.IsDeleted=0 ) AND (stl.QuantityOnHand > 0)) AND (@StockLineIds IS NULL OR stl.NonStockInventoryId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))			     
						AND stl.MasterCompanyId=@MasterCompanyId AND (@MasterPartId IS NULL OR stl.MasterPartId = @MasterPartId)					
						AND stl.IsParent = 1
				), ResultCount AS(Select COUNT(NonStockInventoryId) AS totalItems FROM Result)
				SELECT * INTO #TempResults FROM  Result
				 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
						(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
						(Manufacturer LIKE '%' +@GlobalFilter+'%') OR					
						(PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR						
						(QuantityRejected LIKE '%' +@GlobalFilter+'%') OR						
						(UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR										
						(QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR
						(Quantity LIKE '%' +@GlobalFilter+'%') OR
						(SerialNumber LIKE '%' +@GlobalFilter+'%') OR
						(NonStockInventoryNumber LIKE '%' +@GlobalFilter+'%') OR					
						(ControlNumber LIKE '%' +@GlobalFilter+'%') OR
						(IdNumber LIKE '%' +@GlobalFilter+'%') OR
						(Condition LIKE '%' +@GlobalFilter+'%') OR
						(VendorName LIKE '%' +@GlobalFilter+'%') OR
						(LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
						(AllMSlevels LIKE '%' +@GlobalFilter+'%') OR
						(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
						OR   
						(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
						(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
						(ISNULL(@NonStockInventoryNumber,'') ='' OR NonStockInventoryNumber LIKE '%' + @NonStockInventoryNumber + '%') AND
						(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND				
						(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND
						(ISNULL(@QuantityRejected,'') ='' OR QuantityRejected LIKE '%' + @QuantityRejected + '%') AND
						(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND					
						(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
						(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND
						(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
						(ISNULL(@ExtendedCost,'') ='' OR ExtendedCost LIKE '%' + @ExtendedCost + '%') AND
						(ISNULL(@Acquired,'') ='' OR Acquired LIKE '%' + @Acquired + '%') AND					
						(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND
						(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
						(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ReceivedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@ReceivedDate AS date)) AND
						(ISNULL(@OrderDate,'') ='' OR CAST(OrderDate AS Date)=CAST(@OrderDate AS date)) AND					
						(ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS Date)=CAST(@EntryDate AS date)) AND
						(ISNULL(@MfgExpirationDate,'') ='' OR CAST(MfgExpirationDate AS Date)=CAST(@MfgExpirationDate AS date)) AND
						(ISNULL(@NonStockClassification,'') ='' OR NonStockClassification LIKE '%' + @NonStockClassification + '%') AND
						(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
						(ISNULL(@LastMSLevel,'') ='' OR AllMSlevels LIKE '%' + @LastMSLevel + '%') AND						
						(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
						(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					   )
					   SELECT @Count = COUNT(NonStockInventoryId) FROM #TempResults			

					SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY  
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='NonStockInventoryNumber')  THEN NonStockInventoryNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='NonStockInventoryNumber')  THEN NonStockInventoryNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC, 			
						CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC, 
						CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='Acquired')  THEN Acquired END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Acquired')  THEN Acquired END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='NonStockClassification')  THEN NonStockClassification END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='NonStockClassification')  THEN NonStockClassification END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='OrderDate')  THEN OrderDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='OrderDate')  THEN OrderDate END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='MfgExpirationDate')  THEN MfgExpirationDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='MfgExpirationDate')  THEN MfgExpirationDate END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC	
				
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
				ELSE -- ALL
				BEGIN
					;WITH Result AS(
					SELECT DISTINCT 
							stl.NonStockInventoryId as NonStockInventoryId,				
						   (ISNULL(im.MasterPartId,0)) 'ItemMasterId',
						   (ISNULL(im.MasterPartId,0)) 'MasterPartId',
						   (ISNULL(im.PartNumber,'')) 'PartNumber',
						   (ISNULL(im.PartDescription,'')) 'PartDescription',
						   (ISNULL(stl.Manufacturer,'')) 'Manufacturer',  
						   (ISNULL(stl.PurchaseOrderNumber,'')) 'PurchaseOrderNumber', 
						   (ISNULL(stl.PurchaseOrderId,0)) 'PurchaseOrderId',
						   (ISNULL(stl.PurchaseOrderPartRecordId,0)) 'PurchaseOrderPartRecordId',
						   (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',						   					   
						   (ISNULL(stl.SerialNumber,'')) 'SerialNumber',
						   (ISNULL(stl.NonStockInventoryNumber,'')) 'NonStockInventoryNumber', 						   
						   (ISNULL(stl.Condition,'')) AS  'Condition', 					   
						   (ISNULL(stl.ReceivedDate,'')) AS  'ReceivedDate',
						   (ISNULL(stl.OrderDate,''))AS  'OrderDate',					  
						   (ISNULL(stl.EntryDate,'')) AS 'EntryDate',
						   (ISNULL(stl.MfgExpirationDate,'')) AS 'MfgExpirationDate',
						   (ISNULL(stl.GLAccount,'')) 'GLAccount',
						   (ISNULL(stl.UnitCost,0))as  'UnitCost',	
						   (ISNULL(stl.ExtendedCost,0)) as 'ExtendedCost',					   
						   (ISNULL(stl.Acquired,0)) 'Acquired', 						   	
						   (ISNULL(stl.NonStockClassification,'')) as 'NonStockClassification',	
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',						   
						   CAST(stl.QuantityRejected AS varchar) 'QuantityRejected',						   
						   CAST(stl.Quantity AS varchar) 'Quantity',
						   stl.QuantityRejected  as QuantityRejectednew,
						   stl.QuantityOnHand  as QuantityOnHandnew,
						   stl.Quantity  as Quantitynew,
						   stl.ControlNumber,
						   stl.IdNumber,
						   stl.IsHazardousMaterial as 'IsHazardousMaterial',
						   stl.IsActive,                     
						   stl.CreatedDate,
						   stl.CreatedBy,
						   stl.VendorName,
						   stl.Requisitioner,
						   stl.ReceiverNumber,
						   stl.UpdatedDate,					   
						   stl.UpdatedBy,
						   MSD.LastMSLevel,
						   MSD.AllMSlevels	
					 FROM  NonStockInventory stl WITH (NOLOCK)
							INNER JOIN ItemMasterNonStock im WITH (NOLOCK) ON stl.MasterPartId = im.MasterPartId 
							INNER JOIN  dbo.NonStocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.NonStockInventoryId AND MSD.ModuleID = @MSModuelId
		 		  WHERE ((stl.IsDeleted=0 ) AND (@stockTypeId IS NULL OR im.ItemTypeId=@stockTypeId)) AND (@StockLineIds IS NULL OR stl.NonStockInventoryId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))			     
						AND stl.MasterCompanyId=@MasterCompanyId AND (@MasterPartId IS NULL OR stl.MasterPartId = @MasterPartId)					
						AND stl.IsParent = 1
				), ResultCount AS(Select COUNT(NonStockInventoryId) AS totalItems FROM Result)
				SELECT * INTO #TempResult FROM  Result
				 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
						(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
						(Manufacturer LIKE '%' +@GlobalFilter+'%') OR					
						(PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR						
						(QuantityRejected LIKE '%' +@GlobalFilter+'%') OR						
						(UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR										
						(QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR
						(Quantity LIKE '%' +@GlobalFilter+'%') OR
						(SerialNumber LIKE '%' +@GlobalFilter+'%') OR
						(NonStockInventoryNumber LIKE '%' +@GlobalFilter+'%') OR					
						(ControlNumber LIKE '%' +@GlobalFilter+'%') OR
						(IdNumber LIKE '%' +@GlobalFilter+'%') OR
						(Condition LIKE '%' +@GlobalFilter+'%') OR
						(VendorName LIKE '%' +@GlobalFilter+'%') OR
						(LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
						(AllMSlevels LIKE '%' +@GlobalFilter+'%') OR					
						(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
						OR   
						(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
						(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
						(ISNULL(@NonStockInventoryNumber,'') ='' OR NonStockInventoryNumber LIKE '%' + @NonStockInventoryNumber + '%') AND
						(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND				
						(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND
						(ISNULL(@QuantityRejected,'') ='' OR QuantityRejected LIKE '%' + @QuantityRejected + '%') AND
						(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND					
						(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
						(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND
						(ISNULL(@ExtendedCost,'') ='' OR ExtendedCost LIKE '%' + @ExtendedCost + '%') AND
						(ISNULL(@Acquired,'') ='' OR Acquired LIKE '%' + @Acquired + '%') AND					
						(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND
						(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
						(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
						(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ReceivedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@ReceivedDate AS date)) AND
						(ISNULL(@OrderDate,'') ='' OR CAST(OrderDate AS Date)=CAST(@OrderDate AS date)) AND					
						(ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS Date)=CAST(@EntryDate AS date)) AND
						(ISNULL(@MfgExpirationDate,'') ='' OR CAST(MfgExpirationDate AS Date)=CAST(@MfgExpirationDate AS date)) AND
						(ISNULL(@NonStockClassification,'') ='' OR NonStockClassification LIKE '%' + @NonStockClassification + '%') AND
						(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
						(ISNULL(@LastMSLevel,'') ='' OR AllMSlevels LIKE '%' + @LastMSLevel + '%') AND
						(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
						(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					   )
					   SELECT @Count = COUNT(NonStockInventoryId) FROM #TempResult			

					SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='NonStockInventoryNumber')  THEN NonStockInventoryNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='NonStockInventoryNumber')  THEN NonStockInventoryNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC, 			
						CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC, 
						CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='Acquired')  THEN Acquired END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Acquired')  THEN Acquired END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='NonStockClassification')  THEN NonStockClassification END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='NonStockClassification')  THEN NonStockClassification END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='OrderDate')  THEN OrderDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='OrderDate')  THEN OrderDate END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='MfgExpirationDate')  THEN MfgExpirationDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='MfgExpirationDate')  THEN MfgExpirationDate END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC	
				
				
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
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'ProcStockList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter6 = ' + ISNULL(@stockTypeId,'') + ', 
													   @Parameter7 = ' + ISNULL(@NonStockInventoryNumber,'') + ', 
													   @Parameter8 = ' + ISNULL(@PartNumber,'') + ', 
													   @Parameter9 = ' + ISNULL(@PartDescription,'') + ', 
													   @Parameter10 = ' + ISNULL(@ControlNumber,'') + ', 
													   @Parameter11 = ' + ISNULL(@UnitOfMeasure,'') + ', 
													   @Parameter12 = ' + ISNULL(@SerialNumber,'') + ', 
													   @Parameter13 = ' + ISNULL(@GLAccount,'') + ', 
													   @Parameter14 = ' + ISNULL(@ReceiverNumber,'') + ',
													   @Parameter15 = ' + ISNULL(@Condition,'') + ', 
													   @Parameter16 = ' + ISNULL(@Quantity,'') + ', 
													   @Parameter17 = ' + ISNULL(@QuantityOnHand,'') + ', 
													   @Parameter16 = ' + ISNULL(@QuantityRejected,'') + ', 
													   @Parameter21 = ' + ISNULL(@LastMSLevel,'') + ', 
													   @Parameter22 = ' + ISNULL(@Currency,'') + ', 
													   @Parameter23 = ' + ISNULL(@IdNumber,'') + ', 
													   @Parameter24 = ' + ISNULL(CAST(@ReceivedDate AS varchar(20)) ,'') +''',  
													   @Parameter24 = ' + ISNULL(CAST(@OrderDate AS varchar(20)) ,'') +''',  
													   @Parameter24 = ' + ISNULL(CAST(@EntryDate AS varchar(20)) ,'') +''',  
													   @Parameter24 = ' + ISNULL(CAST(@MfgExpirationDate AS varchar(20)) ,'') +''',  
													   @Parameter32 = ' + ISNULL(@Manufacturer,'') + ', 
													   @Parameter33 = ' + ISNULL(@UnitCost,'') + ',
													   @Parameter34 = ' + ISNULL(@ExtendedCost,'') + ', 
													   @Parameter35 = ' + ISNULL(@Acquired,'') + ', 
													   @Parameter33 = ' + ISNULL(@IsHazardousMaterial,'') + ',
													   @Parameter34 = ' + ISNULL(@NonStockClassification,'') + ', 
													   @Parameter35 = ' + ISNULL(@ShippingVia,'') + ', 
													   @Parameter36 = ' + ISNULL(@UpdatedBy,'') + ', 
													   @Parameter37 = ' + ISNULL(CAST(@UpdatedDate AS varchar(20)) ,'') +''',
													   @Parameter36 = ' + ISNULL(@ShippingAccount,'') + ', 
													   @Parameter38 = ' + ISNULL(@EmployeeId,'') + ', 
													   @Parameter39 = ' + ISNULL(@MasterCompanyId,'') + ', 
													   @Parameter36 = ' + ISNULL(@ShippingReference,'') + ', 
													   @Parameter40 = ' + ISNULL(@Memo ,'') +''
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