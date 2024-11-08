/*************************************************************           
 ** File:   [SOQSODashboardData]
 ** Author: Deep Patel
 ** Description: This stored procedure is used to Get SOQSO Dashboard Details
 ** Purpose:         
 ** Date:   19-July-2022       
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1	19-July-2022	Deep Patel		Created
	2	01-JAN-2024		AMIT GHEDIYA	added isperforma Flage for SO
	3   16-OCT-2024		Abhishek JirawlaImplemented the new tables for SalesOrderQuotePart related tables (Needs to be revisited)

************************************************************************/
CREATE PROCEDURE [dbo].[SOQSODashboardData]
	-- Add the parameters for the stored procedure here
	@PageSize int,
	@PageNumber int,	
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@GlobalFilter varchar(50) = '',
	@SalesOrderNumber varchar(50)=null,
	@SalesOrderQuoteNumber varchar(50)=null,
	@CustomerName varchar(50)=null,
	@Status varchar(50)=null,
    @EstRevenue numeric(18,4)=null,
	@EstCost numeric(18,4)=null,
	@OpenDate varchar(50)=null,
    @SalesPerson varchar(50)=null,
    @Priority varchar(50)=null,
	@RequestedDate varchar(50)=null,
    @EstimatedShipDate varchar(50)=null,
	@PartNumber varchar(50)=null,
    @PartDescription varchar(50)=null,
	@MasterCompanyId int = null,
	@EmployeeId bigint,
	@Opr int,
	@Type varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom int;
				SET @RecordFrom = (@PageNumber-1)*@PageSize;
				--IF @IsDeleted is null
				--Begin
				--	Set @IsDeleted=0
				--End
				--print @IsDeleted	
				IF @SortColumn is null
				Begin
					Set @SortColumn=Upper('CreatedDate')
				End 
				Else
				Begin 
					Set @SortColumn=Upper(@SortColumn)
				End

				If @EstRevenue=0
				Begin 
					Set @EstRevenue=null
				End
		
				If @EstCost=0
				Begin 
					Set @EstCost=null
				End


				--If @StatusID=0
				--Begin 
				--	Set @StatusID=null
				--End 

				If @Status='0'
				Begin
					Set @Status=null
				End
				DECLARE @CustomerAffiliation varchar(20);
				IF(@Type = 'internal')
				BEGIN
					SET @CustomerAffiliation = '1';
				END
				ELSE IF(@Type = 'external')
				BEGIN
					SET @CustomerAffiliation = '2';
				END
				ELSE IF(@Type = 'all')
				BEGIN
					SET @CustomerAffiliation = '1,2,3';
				END
				ELSE
				BEGIN
					SET @CustomerAffiliation = '1,2,3';
				END
				DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID
				DECLARE @MSSOModuleID INT = 17; -- Sales Order Management Structure Module ID
			-- Insert statements for procedure here
			IF(@Opr = 1)
			BEGIN
			;With Result AS(
				Select SOQ.SalesOrderQuoteId as 'RefId',SOQ.SalesOrderQuoteNumber,SOQ.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				,ISNULL(SUM(SPC.NetSaleAmount),0)as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue'
				from SalesOrderQuote SOQ WITH (NOLOCK)
				Inner Join MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SOQ.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SOQ.AccountTypeId
				LEFT Join SalesOrderQuotePartV1 SP WITH (NOLOCK) on SOQ.SalesOrderQuoteId=SP.SalesOrderQuoteId and SP.IsDeleted=0
				LEFT JOIN SalesOrderQuotePartCost SPC WITH (NOLOCK) on SPC.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SPC.IsDeleted=0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null
				Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				Left Join SalesOrder SO WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				--LEFT JOIN dbo.SalesOrderQuoteFreight SOQF WITH (NOLOCK) ON SOQF.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
				--LEFT JOIN dbo.SalesOrderQuoteCharges SOQC WITH (NOLOCK) ON SOQC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderQuoteFreight SOQF WHERE SOQF.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderQuoteCharges SOQC WHERE SOQC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
		        ) B
				Where (SOQ.IsDeleted=0) AND SOQ.MasterCompanyId = @MasterCompanyId AND SOQ.StatusId=1 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')) GROUP BY SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SOQ.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 2)
			BEGIN
			;With Result AS(
				Select SOQ.SalesOrderQuoteId as 'RefId',SOQ.SalesOrderQuoteNumber,SOQ.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber ,ISNULL(SUM(SPC.NetSaleAmount),0)as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue',
				SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				from SalesOrderQuote SOQ WITH (NOLOCK)
				Inner Join MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SOQ.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SOQ.AccountTypeId
				INNER Join SalesOrderQuotePartV1 SP WITH (NOLOCK) on SOQ.SalesOrderQuoteId=SP.SalesOrderQuoteId and SP.IsDeleted=0
				LEFT JOIN SalesOrderQuotePartCost SPC WITH (NOLOCK) on SPC.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SPC.IsDeleted=0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null
				Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				Left Join SalesOrder SO WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = SP.SalesOrderQuotePartId AND SOQAP.InternalStatusId=4
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderQuoteFreight SOQF WHERE SOQF.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderQuoteCharges SOQC WHERE SOQC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
		        ) B
				--Where (SOQ.IsDeleted=0) AND SOQ.MasterCompanyId = @MasterCompanyId and (SOQ.IsEnforceApproval = 1)),
				Where (SOQ.IsDeleted=0) AND SOQ.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')) GROUP BY SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SOQ.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 3)
				BEGIN
				;With Result AS(
				Select SOQ.SalesOrderQuoteId as 'RefId',SOQ.SalesOrderQuoteNumber,SOQ.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber
				,ISNULL(SUM(SPC.NetSaleAmount),0) as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue',
				SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				from SalesOrderQuote SOQ WITH (NOLOCK)
				Inner Join MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SOQ.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SOQ.AccountTypeId
				INNER Join SalesOrderQuotePartV1 SP WITH (NOLOCK) on SOQ.SalesOrderQuoteId=SP.SalesOrderQuoteId and SP.IsDeleted=0
				LEFT JOIN SalesOrderQuotePartCost SPC WITH (NOLOCK) on SPC.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SPC.IsDeleted=0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null
				Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				Left Join SalesOrder SO WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = SP.SalesOrderQuotePartId AND SOQAP.CustomerStatusId=4
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderQuoteFreight SOQF WHERE SOQF.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderQuoteCharges SOQC WHERE SOQC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
		        ) B
				--Where (SOQ.IsDeleted=0) AND SOQ.MasterCompanyId = @MasterCompanyId and (SOQ.IsEnforceApproval = 0)),
				Where (SOQ.IsDeleted=0) AND SOQ.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')) GROUP BY SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SOQ.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 4)
				BEGIN
				;With Result AS(
				Select SO.SalesOrderId as 'RefId',SOQ.SalesOrderQuoteNumber,SO.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber
				,ISNULL(SUM(SPC.NetSaleAmount),0) as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue'
				,SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				from SalesOrder SO WITH (NOLOCK)
				Inner Join MasterSalesOrderStatus MST WITH (NOLOCK) on SO.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SO.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SO.AccountTypeId
				INNER Join SalesOrderPartV1 SP WITH (NOLOCK) on SO.SalesOrderId=SP.SalesOrderId and SP.IsDeleted=0
				LEFT JOIN SalesOrderPartCost SPC WITH (NOLOCK) on SPC.SalesOrderPartId=SP.SalesOrderPartId and SPC.IsDeleted=0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SO.SalesPersonId --and SOQ.SalesPersonId is not null
				Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				Left Join SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderQuotePart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSSOModuleID AND MSD.ReferenceID = SO.SalesOrderId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = SP.SalesOrderPartId AND SOAPR.InternalStatusId=4
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderFreight SOQF WHERE SOQF.SalesOrderPartId = SP.SalesOrderPartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderCharges SOQC WHERE SOQC.SalesOrderPartId = SP.SalesOrderPartId
		        ) B
				--Where (SOQ.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId and (SO.IsEnforceApproval = 1)),
				Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')) GROUP BY SO.SalesOrderId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SO.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 5)
				BEGIN
				;With Result AS(
				Select SO.SalesOrderId as 'RefId',SOQ.SalesOrderQuoteNumber,SO.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber
				--,ISNULL(SP.NetSales,0)as 'EstRevenue',ISNULL(SP.NetSales,0) as 'EstCost'
				--,ISNULL(SUM(SP.NetSales),0) + ISNULL(A.Freight,0)as 'EstCost',
				,ISNULL(SUM(SPC.NetSaleAmount),0) as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue'
				,SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				from SalesOrder SO WITH (NOLOCK)
				Inner Join MasterSalesOrderStatus MST WITH (NOLOCK) on SO.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SO.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SO.AccountTypeId
				INNER Join SalesOrderPartV1 SP WITH (NOLOCK) on SO.SalesOrderId=SP.SalesOrderId and SP.IsDeleted=0
				LEFT JOIN SalesOrderPartCost SPC WITH (NOLOCK) on SPC.SalesOrderPartId=SP.SalesOrderPartId and SPC.IsDeleted=0			
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SO.SalesPersonId --and SOQ.SalesPersonId is not null
				Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				Left Join SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderQuotePart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSSOModuleID AND MSD.ReferenceID = SO.SalesOrderId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = SP.SalesOrderPartId AND SOAPR.CustomerStatusId=4
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderFreight SOQF WHERE SOQF.SalesOrderPartId = SP.SalesOrderPartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderCharges SOQC WHERE SOQC.SalesOrderPartId = SP.SalesOrderPartId
		        ) B
				--Where (SOQ.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId and (SO.IsEnforceApproval = 0)),
				Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')) GROUP BY SO.SalesOrderId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SO.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 6)
				BEGIN
				;With Result AS(
				Select SO.SalesOrderId as 'RefId',SOQ.SalesOrderQuoteNumber,SO.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber,
				--ISNULL(SUM(SP.NetSales),0)as 'EstRevenue',ISNULL(SUM(SP.NetSales),0) as 'EstCost',
				--ISNULL(SUM(SP.NetSales),0) + ISNULL(A.Freight,0)as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(SUM(B.Charges),0)as 'EstRevenue',
				SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate',
				SP.ConditionId,SP.ItemMasterId
				from SalesOrder SO WITH (NOLOCK)
				INNER JOIN MasterSalesOrderStatus MST WITH (NOLOCK) on SO.StatusId=MST.Id
				INNER JOIN Customer C WITH (NOLOCK) on C.CustomerId=SO.CustomerId
				INNER JOIN CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SO.AccountTypeId
				INNER JOIN SalesOrderPartV1 SP WITH (NOLOCK) on SO.SalesOrderId=SP.SalesOrderId and SP.IsDeleted=0
				LEFT JOIN SalesOrderPartCost SPC WITH (NOLOCK) on SPC.SalesOrderPartId=SP.SalesOrderPartId and SPC.IsDeleted=0
				LEFT JOIN ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				LEFT JOIN Employee E WITH (NOLOCK) on  E.EmployeeId=SO.SalesPersonId --and SOQ.SalesPersonId is not null
				LEFT JOIN Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				LEFT JOIN SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderQuotePart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSSOModuleID AND MSD.ReferenceID = SO.SalesOrderId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				--INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON SO.SalesOrderId = SOS.SalesOrderId
				--INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SO.SalesOrderId = SOS.SalesOrderId AND SP.SalesOrderPartId != SOSI.SalesOrderPartId
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderFreight SOQF WHERE SOQF.SalesOrderPartId = SP.SalesOrderPartId
		  --      ) A
			    OUTER APPLY
			    (
					--SELECT SOQC.SalesOrderPartId,SUM(SOQC.BillingAmount) AS Charges from SalesOrderCharges SOQC WHERE SOQC.SalesOrderPartId = SP.SalesOrderPartId
					--AND SOQC.ItemMasterId = SP.ItemMasterId and SOQC.ConditionId = SP.ConditionId group by SOQC.SalesOrderPartId

					SELECT SOQC.BillingAmount AS Charges from SalesOrderCharges SOQC WHERE SOQC.SalesOrderPartId = SP.SalesOrderPartId
					AND SOQC.ItemMasterId = SP.ItemMasterId and SOQC.ConditionId = SP.ConditionId group by SOQC.ItemMasterId,SOQC.BillingAmount,SOQC.ConditionId
		        ) B
				Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId and (SO.StatusId = 10) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				
				--AND SP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderShippingItem)
				
				GROUP BY SO.SalesOrderId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SO.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate
				--A.Freight,
				),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 7)
				BEGIN
				;With Result AS(
				Select SO.SalesOrderId as 'RefId',SOQ.SalesOrderQuoteNumber,SO.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber,
				--ISNULL(SP.NetSales,0)as 'EstRevenue',ISNULL(SP.NetSales,0) as 'EstCost',
				--ISNULL(SUM(SP.NetSales),0) + ISNULL(A.Freight,0)as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue',
				SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				from SalesOrder SO WITH (NOLOCK)
				INNER JOIN MasterSalesOrderStatus MST WITH (NOLOCK) on SO.StatusId=MST.Id
				INNER JOIN Customer C WITH (NOLOCK) on C.CustomerId=SO.CustomerId
				INNER JOIN CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SO.AccountTypeId
				INNER JOIN SalesOrderPartV1 SP WITH (NOLOCK) on SO.SalesOrderId=SP.SalesOrderId and SP.IsDeleted=0
				LEFT JOIN SalesOrderPartCost SPC WITH (NOLOCK) on SPC.SalesOrderPartId=SP.SalesOrderPartId and SPC.IsDeleted=0
				LEFT JOIN ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				LEFT JOIN Employee E WITH (NOLOCK) on  E.EmployeeId=SO.SalesPersonId --and SOQ.SalesPersonId is not null
				LEFT JOIN Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				LEFT JOIN SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderQuotePart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSSOModuleID AND MSD.ReferenceID = SO.SalesOrderId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				--INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON SO.SalesOrderId = SOS.SalesOrderId
			    --INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SO.SalesOrderId = SOS.SalesOrderId AND SP.SalesOrderPartId = SOSI.SalesOrderPartId
				INNER JOIN DBO.SalesOrderApproval SOAPR WITH (NOLOCK) ON SO.SalesOrderId = SOAPR.SalesOrderId AND SP.SalesOrderPartId = SOAPR.SalesOrderPartId AND SOAPR.CustomerStatusId=2
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderFreight SOQF WHERE SOQF.SalesOrderPartId = SP.SalesOrderPartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderCharges SOQC WHERE SOQC.SalesOrderPartId = SP.SalesOrderPartId
		        ) B
				--Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId and (SO.StatusId = 10)),
				Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId AND SO.StatusId != 2 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				--AND SP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderBillingInvoicingItem)
				AND SP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderShippingItem)
				GROUP BY SO.SalesOrderId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SO.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
					
				END
				IF(@Opr = 8)
				BEGIN
				;With Result AS(
				Select SO.SalesOrderId as 'RefId',SOQ.SalesOrderQuoteNumber,SO.OpenDate as 'OpenDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',IsNull(P.Description,'') as 'Priority',(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber',IsNull(im.PartDescription,'') as 'PartDescription',
				SO.SalesOrderNumber,
				ISNULL(SUM(SPC.NetSaleAmount),0) as 'EstCost',
				ISNULL(SUM(SPC.NetSaleAmount),0) + ISNULL(B.Charges,0)as 'EstRevenue',
				SP.EstimatedShipDate,SP.CustomerRequestDate as 'RequestedDate'
				from SalesOrder SO WITH (NOLOCK)
				Inner Join MasterSalesOrderStatus MST WITH (NOLOCK) on SO.StatusId=MST.Id
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId=SO.CustomerId
				Inner Join CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SO.AccountTypeId
				INNER Join SalesOrderPartV1 SP WITH (NOLOCK) on SO.SalesOrderId=SP.SalesOrderId and SP.IsDeleted=0
				LEFT JOIN SalesOrderPartCost SPC WITH (NOLOCK) on SPC.SalesOrderPartId=SP.SalesOrderPartId and SPC.IsDeleted=0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SO.SalesPersonId --and SOQ.SalesPersonId is not null
				Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId
				Left Join SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
				--Left Join SalesOrderQuotePart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSSOModuleID AND MSD.ReferenceID = SO.SalesOrderId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				--INNER JOIN DBO.SalesOrderBillingInvoicing SOS WITH (NOLOCK) ON SP.SalesOrderId = SOS.SalesOrderId AND SOS.IsDeleted=0
			 --   INNER JOIN DBO.SalesOrderBillingInvoicingItem SOSI WITH (NOLOCK) ON SP.SalesOrderId = SOS.SalesOrderId AND SP.SalesOrderPartId = SOSI.SalesOrderPartId
				--INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON SO.SalesOrderId = SOS.SalesOrderId
			    INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SP.SalesOrderPartId = SOSI.SalesOrderPartId
				--OUTER APPLY
			 --   (
				--	SELECT SUM(SOQF.BillingAmount) AS Freight from SalesOrderFreight SOQF WHERE SOQF.SalesOrderPartId = SP.SalesOrderPartId
		  --      ) A
			    OUTER APPLY
			    (
					SELECT SUM(SOQC.BillingAmount) AS Charges from SalesOrderCharges SOQC WHERE SOQC.SalesOrderPartId = SP.SalesOrderPartId
		        ) B
				--Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId and (SO.StatusId = 10)),
				Where (SO.IsDeleted=0) AND SO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ',')) 
				AND SP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderBillingInvoicingItem WHERE ISNULL(IsProforma,0) = 0)
				GROUP BY SO.SalesOrderId,SOQ.SalesOrderQuoteNumber,SP.ConditionId,SP.ItemMasterId,SO.OpenDate
				,C.CustomerId,C.Name,MST.Name,P.Description,E.FirstName,E.LastName,IM.partnumber,im.PartDescription,SO.SalesOrderNumber,SP.EstimatedShipDate,SP.CustomerRequestDate,
				--A.Freight,
				B.Charges),
				FinalResult AS (SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,
					Priority,SalesPerson,PartNumber,PartDescription,SalesOrderNumber,
					EstRevenue,EstCost, EstimatedShipDate,RequestedDate from Result
				Where (
					(@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%') OR
							(Priority like '%' +@GlobalFilter+'%') OR
							(EstRevenue like '%' +@GlobalFilter+'%') OR
							(EstCost like '%' +@GlobalFilter+'%') OR
							(PartNumber like '%' +@GlobalFilter+'%') OR
							(PartDescription like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@SalesOrderQuoteNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SalesOrderQuoteNumber+'%') and 
							(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and
							(@EstRevenue is  null or EstRevenue=@EstRevenue) and
							(@EstCost is  null or EstCost=@EstCost) and
							(@EstimatedShipDate is  null or Cast(EstimatedShipDate as date)=Cast(@EstimatedShipDate as date)) and
							(@RequestedDate is  null or Cast(RequestedDate as date)=Cast(@RequestedDate as date)) and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@Priority,'') ='' OR Priority like '%'+ @Priority+'%') and
							(IsNull(@PartNumber,'') ='' OR PartNumber like '%'+@PartNumber+'%') and
							(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)
					SELECT RefId,SalesOrderQuoteNumber,OpenDate,CustomerId,CustomerName,Status,EstRevenue,EstCost
					,EstimatedShipDate,RequestedDate,Priority,SalesPerson,PartNumber,PartDescription,PartDescription,SalesOrderNumber,
					NumberOfItems from FinalResult, ResultCount
				ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOST')  THEN EstCost END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTREVENUE')  THEN EstRevenue END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOST')  THEN EstCost END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN Priority END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc
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
              , @AdhocComments     VARCHAR(150)    = 'SearchPNViewData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
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