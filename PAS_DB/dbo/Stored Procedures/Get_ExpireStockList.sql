
CREATE PROCEDURE [dbo].[Get_ExpireStockList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StocklineNumber varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@ReceivedDate datetime = NULL,
@TagDate datetime = NULL,
@ExpirationDate datetime = NULL,
@Manufacturer varchar(50) = NULL,
@CreatedDate  datetime = NULL,
@EmployeeId BIGINT=NULL,
@MasterCompanyId BIGINT = NULL,
@expDate datetime = NULL,
@expDays  varchar(50)=null,
@MSModuelId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		DECLARE @RecordFrom INT;
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;	

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END	


		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				
					;WITH Result AS(
					SELECT DISTINCT stl.StockLineId,				
						   (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
						   (ISNULL(im.PartNumber,'')) 'PartNumber',
						   (ISNULL(im.PartDescription,'')) 'PartDescription',
						   (ISNULL(stl.Manufacturer,'')) 'Manufacturer',  
						   (ISNULL(rPart.PartNumber,'')) 'RevisedPN', 					    
						   (ISNULL(stl.ItemGroup,'')) 'ItemGroup', 
						   (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
						   stl.QuantityOnHand  as QuantityOnHandnew,
						   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
						   stl.QuantityAvailable  as QuantityAvailablenew,
						   CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',
						   (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber', 
						   stl.ControlNumber,
						   stl.IdNumber,
						   (ISNULL(stl.Condition,'')) 'Condition', 					   
						   (ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',
						   (ISNULL(stl.ShippingReference,'')) 'AWB',					  
						   stl.ExpirationDate 'ExpirationDate',
						   stl.TagDate 'TagDate',
						   (ISNULL(stl.TaggedByName,'')) 'TaggedByName',
						   (ISNULL(stl.TagType,'')) 'TagType',	
						   (ISNULL(stl.TraceableToName,'')) 'TraceableToName',					   
						   (ISNULL(stl.itemType,'')) 'ItemCategory',
						   im.ItemTypeId,
						   stl.IsActive,                     
						   stl.CreatedDate,
						   stl.CreatedBy,
						   stl.PartCertificationNumber,
						   stl.CertifiedBy,
						   stl.CertifiedDate,
						   stl.UpdatedDate,					   
						   stl.UpdatedBy,
						   CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,
						   stl.ObtainFromName AS obtainFrom,
						   stl.OwnerName AS ownerName,
						   MSD.LastMSLevel,
						   MSD.AllMSlevels
						  ,stl.DaysReceived
						  ,stl.ManufacturingDays
						  ,stl.TagDays
						  ,stl.OpenDays
						  ,isnull((select [dbo].[FN_GetExpireDaysStockline](StocklineId)) ,0)as expDays 
						  ,(DATEADD(DAY, isnull((select [dbo].[FN_GetExpireDaysStockline](StocklineId)),0), GETDATE())) as expDate
					 FROM  StockLine stl WITH (NOLOCK)
							INNER JOIN ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
							INNER JOIN  dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId
							LEFT JOIN ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId						    
		 		  WHERE (stl.IsDeleted=0 ) and (stl.QuantityOnHand >0 or stl.QuantityAvailable >0 )
				    AND ((stl.DaysReceived > 0 or stl.ReceivedDate is not null) or (stl.ManufacturingDays > 0 or stl.ExpirationDate is not null) or (stl.TagDays > 0 or stl.TagDate is not null) or (stl.OpenDays > 0)) 
						AND stl.IsParent = 1
				), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)
				SELECT * INTO #TempResults FROM  Result
				 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
						(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
						(Manufacturer LIKE '%' +@GlobalFilter+'%') OR					
						(StocklineNumber LIKE '%' +@GlobalFilter+'%') OR					
						(expDate LIKE '%' +@GlobalFilter+'%') OR
						(expDays LIKE '%' +@GlobalFilter+'%') OR
						(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
						OR   
						(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
						(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
						(ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND					
						(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND
						(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND					
						(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND
						(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
						(ISNULL(@expDays,'') ='' OR expDays LIKE '%' + @expDays + '%') AND
						(ISNULL(@expDate,'') ='' OR CAST(expDate AS Date)=CAST(@expDate AS date)))
					   )
					   SELECT @Count = COUNT(StockLineId) FROM #TempResults			

					SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY  
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='expDate')  THEN expDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='expDate')  THEN expDate END DESC,						
						CASE WHEN (@SortOrder=1 and @SortColumn='expDays')  THEN expDays END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='expDays')  THEN expDays END DESC
				
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
              , @AdhocComments     VARCHAR(150)    = 'Get_ExpireStockList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter6 = ' + ISNULL(@StocklineNumber,'') + ', 
													   @Parameter7 = ' + ISNULL(@PartNumber,'') + ', 
													   @Parameter8 = ' + ISNULL(@PartDescription,'') + ', 
													   @Parameter9 = ' + ISNULL(CAST(@ReceivedDate AS varchar(20)) ,'') +''',  
													   @Parameter10 = ' + ISNULL(CAST(@TagDate AS varchar(20)) ,'') +''',  
													   @Parameter11 = ' + ISNULL(CAST(@ExpirationDate AS varchar(20)) ,'') +''', 
													   @Parameter12 = ' + ISNULL(@Manufacturer,'') + ', 
													   @Parameter13 = ' + ISNULL(CAST(@CreatedDate AS varchar(20)) ,'') +''',
													   @Parameter14 = ' + ISNULL(@EmployeeId,'') + ', 
													   @Parameter15 = ' + ISNULL(@MasterCompanyId,'') + ', 
													   @Parameter16 = ' + ISNULL(@expDate,'') + ', 
													   @Parameter17 = ' + ISNULL(@expDays,'') + ',
													   @Parameter18 = ' + ISNULL(@MSModuelId,'') +''
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